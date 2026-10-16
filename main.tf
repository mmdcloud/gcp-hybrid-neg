resource "random_password" "shared_secret_0" {
  length  = 32
  special = false
}

resource "random_password" "shared_secret_1" {
  length  = 32
  special = false
}

locals {
  psk_tunnel_0 = "vpn_${random_password.shared_secret_0.result}"
  psk_tunnel_1 = "vpn_${random_password.shared_secret_1.result}"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "gcp_vpc" {
  source                          = "./modules/gcp/vpc"
  vpc_name                        = "gcp-vpc"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  subnets = [
    {
      name                     = "workload-subnet"
      region                   = var.gcp_region
      purpose                  = "PRIVATE"
      role                     = "ACTIVE"
      private_ip_google_access = true
      ip_cidr_range            = "10.10.1.0/24"
    },
    {
      name                     = "hybrid-neg-subnet"
      region                   = var.gcp_region
      purpose                  = "PRIVATE"
      role                     = "ACTIVE"
      private_ip_google_access = true
      ip_cidr_range            = "10.20.1.0/24"
    }
  ]
  firewall_data = [
    {
      name          = "allow-from-aws"
      description   = "Allow all ingress traffic from AWS VPC subnets"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["10.0.0.0/16"]
      allow_list = [
        {
          protocol = "all"
        }
      ]
    },
    {
      name          = "allow-health-checks"
      description   = "Allow Google Cloud Load Balancer health check probes"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    }
  ]
}

resource "google_compute_router" "router" {
  name    = "cr-ha-vpn"
  region  = var.gcp_region
  network = module.gcp_vpc.vpc_name

  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    advertised_ip_ranges {
      range       = "35.191.0.0/16"
      description = "Google Cloud Health Check Probes"
    }

    advertised_ip_ranges {
      range       = "130.211.0.0/22"
      description = "Google Cloud Health Check Probes"
    }
  }
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name    = "gcp-ha-vpn-gw"
  region  = var.gcp_region
  network = module.gcp_vpc.vpc_name
}

module "aws_vpc" {
  source                  = "./modules/aws/vpc"
  vpc_name                = "aws-vpc"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false
  tags = {
    Project = "aws-vpc"
  }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id          = module.aws_vpc.vpc_id
  amazon_side_asn = 64512

  tags = {
    Name = "aws-vgw-gcp"
  }
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = module.aws_vpc.vpc_main_route_table_id
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count          = length(module.aws_vpc.private_route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = module.aws_vpc.private_route_table_ids[count.index]
}

resource "aws_customer_gateway" "gcp_cgw_0" {
  bgp_asn    = 64514 # GCP Cloud Router ASN
  ip_address = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "gcp-customer-gw-0"
  }
}

resource "aws_customer_gateway" "gcp_cgw_1" {
  bgp_asn    = 64514 # GCP Cloud Router ASN
  ip_address = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "gcp-customer-gw-1"
  }
}

resource "aws_vpn_connection" "vpn_conn_0" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw_0.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel1_preshared_key = local.psk_tunnel_0
  tunnel1_ike_versions  = ["ikev2"]

  tags = {
    Name = "aws-to-gcp-conn-0"
  }
}

resource "aws_vpn_connection" "vpn_conn_1" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = "169.254.11.0/30"
  tunnel1_preshared_key = local.psk_tunnel_1
  tunnel1_ike_versions  = ["ikev2"]

  tags = {
    Name = "aws-to-gcp-conn-1"
  }
}

resource "google_compute_external_vpn_gateway" "external_gw" {
  name            = "peer-gw"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_conn_0.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_conn_1.tunnel1_address
  }
}

resource "google_compute_vpn_tunnel" "tunnel_0" {
  name                            = "ha-vpn-tunnel-0"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gw.id
  peer_external_gateway_interface = 0
  shared_secret                   = local.psk_tunnel_0
  router                          = google_compute_router.router.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel_1" {
  name                            = "ha-vpn-tunnel-1"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gw.id
  peer_external_gateway_interface = 1
  shared_secret                   = local.psk_tunnel_1
  router                          = google_compute_router.router.id
  ike_version                     = 2
}

# AWS Site-to-Site VPN explicitly prohibits the following link-local /30 CIDR blocks because they are reserved for internal AWS infrastructure and link-local services (such as the EC2 metadata endpoint):

# 169.254.0.0/30
# 169.254.1.0/30
# 169.254.2.0/30
# 169.254.3.0/30
# 169.254.4.0/30
# 169.254.5.0/30
# 169.254.169.252/30

# Using 169.254.1.0/30 and 169.254.2.0/30 triggers a provider validation error. Furthermore, inside an AWS Site-to-Site VPN /30 block:

# Host 1 (.1): Automatically allocated to the AWS Virtual Private Gateway (VGW) (tunnel1_vgw_inside_address).
# Host 2 (.2): Allocated to the Customer Gateway (GCP Cloud Router interface) (tunnel1_cgw_inside_address).

resource "google_compute_router_interface" "router_interface_0" {
  name       = "cr-interface-0"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "169.254.10.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_0.name
}

resource "google_compute_router_interface" "router_interface_1" {
  name       = "cr-interface-1"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "169.254.11.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

resource "google_compute_router_peer" "bgp_peer_0" {
  name                      = "bgp-peer-0"
  router                    = google_compute_router.router.name
  region                    = var.gcp_region
  peer_ip_address           = "169.254.10.1"
  peer_asn                  = 64512
  interface                 = google_compute_router_interface.router_interface_0.name
  advertised_route_priority = 100
}

resource "google_compute_router_peer" "bgp_peer_1" {
  name                      = "bgp-peer-1"
  router                    = google_compute_router.router.name
  region                    = var.gcp_region
  peer_ip_address           = "169.254.11.1"
  peer_asn                  = 64512
  interface                 = google_compute_router_interface.router_interface_1.name
  advertised_route_priority = 100
}

# -----------------------------------------------------------------------------
# 1. DATA SOURCES: AMI & Availability Zones
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetches the latest Amazon Linux 2023 minimal AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

# -----------------------------------------------------------------------------
# 2. IAM ROLE & INSTANCE PROFILE (SSM Access, No SSH keys needed)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_role" {
  name_prefix        = "${var.environment}-app-role-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_profile" {
  name_prefix = "${var.environment}-app-profile-"
  role        = aws_iam_role.app_role.name
}

# -----------------------------------------------------------------------------
# 3. SECURITY GROUPS (Strictly Chained)
# -----------------------------------------------------------------------------
module "alb_sg" {
  source = "./modules/aws/security-groups"
  name   = "alb-sg"
  vpc_id = module.aws_vpc.vpc_id

  ingress_rules = [
    {
      description     = "HTTP ingress from allowed private networks"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = var.allowed_ingress_cidrs
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "alb-sg"
  }
}

module "app_sg" {
  source = "./modules/aws/security-groups"
  name   = "app-sg"
  vpc_id = module.aws_vpc.vpc_id

  ingress_rules = [
    {
      description     = "HTTP traffic only from the ALB security group"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.alb_sg.id]
      cidr_blocks     = []
    }
  ]

  egress_rules = [
    {
      description = "Allow egress for OS updates / package repositories via NAT/VPC endpoints"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "app-sg"
  }
}

# -----------------------------------------------------------------------------
# 4. INTERNAL APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------
module "internal_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name_prefix                = "int-lb"
  load_balancer_type         = "application"
  internal                   = true # private IPs only
  vpc_id                     = module.aws_vpc.vpc_id
  subnets                    = module.aws_vpc.private_subnets
  security_groups            = [module.alb_sg.id]
  create_security_group      = false # we're passing our own SG
  drop_invalid_header_fields = true
  enable_deletion_protection = var.environment == "prod" ? true : false

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name_prefix          = "app-tg"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 30
      create_attachment    = false # attach via ASG / aws_lb_target_group_attachment

      health_check = {
        enabled             = true
        path                = "/"
        protocol            = "HTTP"
        port                = "traffic-port"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }

  tags = {
    Name = "${var.environment}-internal-alb"
  }
}

# -----------------------------------------------------------------------------
# 5. LAUNCH TEMPLATE
# -----------------------------------------------------------------------------
module "aws_launch_template" {
  source                               = "./modules/aws/launch_template"
  name                                 = "aws-launch-template"
  description                          = "aws-launch-template"
  ebs_optimized                        = false
  image_id                             = data.aws_ami.ubuntu.id
  instance_type                        = var.instance_type
  instance_initiated_shutdown_behavior = "stop"
  instance_profile_name                = aws_iam_instance_profile.app_profile.name

  network_interfaces = [
    {
      associate_public_ip_address = false
      security_groups             = [module.app_sg.id]
    }
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -xe

    # Detect package manager and install dependencies
    if command -v apt-get &>/dev/null; then
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y nginx curl
      WEB_DIR="/var/www/html"
    elif command -v dnf &>/dev/null; then
      dnf update -y
      dnf install -y nginx curl
      WEB_DIR="/usr/share/nginx/html"
    elif command -v yum &>/dev/null; then
      yum update -y
      yum install -y nginx curl
      WEB_DIR="/usr/share/nginx/html"
    fi

    # Fetch IMDSv2 metadata safely
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)
    if [ -n "$TOKEN" ]; then
      INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id || hostname)
      AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")
    else
      INSTANCE_ID=$(hostname)
      AZ="unknown"
    fi

    # Write index.html to standard web directories
    mkdir -p "$WEB_DIR" /usr/share/nginx/html /var/www/html

    cat <<HTML | tee "$WEB_DIR/index.html" /usr/share/nginx/html/index.html /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head><title>Internal Web Service</title></head>
    <body style="font-family: Arial, sans-serif; text-align: center; margin-top: 50px;">
      <h2>Hello from Internal NGINX</h2>
      <p><b>Instance ID:</b> $INSTANCE_ID</p>
      <p><b>Availability Zone:</b> $AZ</p>
      <p><b>Status:</b> Healthy</p>
    </body>
    </html>
    HTML

    systemctl daemon-reload
    systemctl enable --now nginx
  EOF
  )
}

# -----------------------------------------------------------------------------
# AUTO SCALING GROUP
# -----------------------------------------------------------------------------
module "app_asg" {
  source                    = "./modules/aws/auto_scaling_group"
  name                      = "app-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 180
  force_delete              = true
  target_group_arns         = [module.internal_alb.target_groups["app"].arn]
  vpc_zone_identifier       = module.aws_vpc.private_subnets
  launch_template_id        = module.aws_launch_template.id
  launch_template_version   = "$Latest"
}

# -----------------------------------------------------------------------------
# GCP Load balancer Configuration
# -----------------------------------------------------------------------------
module "hybrid_neg" {
  source       = "./modules/gcp/network_endpoint_groups/hybrid_neg"
  project_id   = var.gcp_project_id
  name         = "hybrid-neg"
  network      = module.gcp_vpc.vpc_name
  subnetwork   = module.gcp_vpc.subnets["hybrid-neg-subnet"].name
  default_port = 80
  endpoints    = var.hybrid_neg_endpoints
  zone         = var.gcp_zone
}

module "gcp_lb" {
  source                   = "./modules/gcp/lb"
  project_id               = var.gcp_project_id
  name                     = "gcp-lb"
  load_balancer_type       = "EXTERNAL"
  region                   = var.gcp_region
  create_proxy_only_subnet = false

  backends = {
    lb = {
      is_default          = true
      protocol            = "HTTP"
      port_name           = "http"
      is_serverless_neg   = false
      manage_health_check = true
      health_check = {
        port         = 80
        request_path = "/"
      }
      groups = [
        {
          group                 = module.hybrid_neg.neg_id
          balancing_mode        = "RATE"
          max_rate_per_endpoint = 100
        }
      ]
    }
  }
  enable_ssl              = false
  enable_http             = true
  managed_ssl_certificate = false
  enable_cloud_armor      = false
}