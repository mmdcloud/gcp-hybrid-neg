# =============================================================================
# AWS <-> GCP HA VPN (4 tunnels, BGP) + GCP external LB -> hybrid NEG -> AWS NLB
# =============================================================================

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

# -----------------------------------------------------------------------------
# Tunnel topology
#
# 2 AWS VPN connections x 2 tunnels each = 4 tunnels, matched to the 4 interfaces
# of the GCP external VPN gateway (FOUR_IPS_REDUNDANCY). Each GCP HA VPN
# interface (0/1) terminates both tunnels of one AWS connection (0/1).
# -----------------------------------------------------------------------------
locals {
  vpn_tunnels = {
    "0-1" = { conn = "0", aws_tunnel = 1, gcp_interface = 0, peer_interface = 0 }
    "0-2" = { conn = "0", aws_tunnel = 2, gcp_interface = 0, peer_interface = 1 }
    "1-1" = { conn = "1", aws_tunnel = 1, gcp_interface = 1, peer_interface = 2 }
    "1-2" = { conn = "1", aws_tunnel = 2, gcp_interface = 1, peer_interface = 3 }
  }

  aws_vpn_connections = {
    "0" = aws_vpn_connection.vpn_conn_0
    "1" = aws_vpn_connection.vpn_conn_1
  }
}

# One PSK per tunnel. AWS rejects PSKs starting with "0", so prefix with a letter.
resource "random_password" "psk" {
  for_each = local.vpn_tunnels
  length   = 32
  special  = false
}

locals {
  psk = { for k, v in random_password.psk : k => "vpn_${v.result}" }
}

# -----------------------------------------------------------------------------
# GCP: VPC, Cloud Router, HA VPN gateway
# -----------------------------------------------------------------------------
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
      description   = "Allow web/ICMP traffic from the AWS VPC"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["10.0.0.0/16"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        },
        {
          protocol = "icmp"
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

    # Advertise the Google LB / health-check source ranges so AWS routes return
    # traffic for them back over the VPN.
    dynamic "advertised_ip_ranges" {
      for_each = toset(var.gcp_lb_source_cidrs)
      content {
        range       = advertised_ip_ranges.value
        description = "Google Cloud LB / health check source range"
      }
    }
  }
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name    = "gcp-ha-vpn-gw"
  region  = var.gcp_region
  network = module.gcp_vpc.vpc_name
}

# -----------------------------------------------------------------------------
# AWS: VPC, VGW, customer gateways, VPN connections
# -----------------------------------------------------------------------------
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
  tags                    = var.tags
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
  bgp_asn    = google_compute_router.router.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "gcp-customer-gw-0"
  }
}

resource "aws_customer_gateway" "gcp_cgw_1" {
  bgp_asn    = google_compute_router.router.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "gcp-customer-gw-1"
  }
}

# Inside CIDRs must be /30s in 169.254.0.0/16 and must avoid the AWS-reserved
# blocks (169.254.0.0/30 - 169.254.5.0/30, 169.254.169.252/30). In each /30,
# .1 is the AWS VGW and .2 is the GCP Cloud Router interface.
resource "aws_vpn_connection" "vpn_conn_0" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw_0.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel1_preshared_key = local.psk["0-1"]
  tunnel1_ike_versions  = ["ikev2"]

  tunnel2_inside_cidr   = "169.254.10.4/30"
  tunnel2_preshared_key = local.psk["0-2"]
  tunnel2_ike_versions  = ["ikev2"]

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
  tunnel1_preshared_key = local.psk["1-1"]
  tunnel1_ike_versions  = ["ikev2"]

  tunnel2_inside_cidr   = "169.254.11.4/30"
  tunnel2_preshared_key = local.psk["1-2"]
  tunnel2_ike_versions  = ["ikev2"]

  tags = {
    Name = "aws-to-gcp-conn-1"
  }
}

# -----------------------------------------------------------------------------
# GCP side of the VPN: external gateway, 4 tunnels, router interfaces, BGP peers
# -----------------------------------------------------------------------------
resource "google_compute_external_vpn_gateway" "external_gw" {
  name            = "peer-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_conn_0.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_conn_0.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.vpn_conn_1.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.vpn_conn_1.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "tunnel" {
  for_each = local.vpn_tunnels

  name                            = "ha-vpn-tunnel-${each.key}"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  vpn_gateway_interface           = each.value.gcp_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gw.id
  peer_external_gateway_interface = each.value.peer_interface
  shared_secret                   = local.psk[each.key]
  router                          = google_compute_router.router.id
  ike_version                     = 2
}

resource "google_compute_router_interface" "interface" {
  for_each = local.vpn_tunnels

  name       = "cr-interface-${each.key}"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "${local.aws_vpn_connections[each.value.conn]["tunnel${each.value.aws_tunnel}_cgw_inside_address"]}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel[each.key].name
}

resource "google_compute_router_peer" "bgp_peer" {
  for_each = local.vpn_tunnels

  name                      = "bgp-peer-${each.key}"
  router                    = google_compute_router.router.name
  region                    = var.gcp_region
  peer_ip_address           = local.aws_vpn_connections[each.value.conn]["tunnel${each.value.aws_tunnel}_vgw_inside_address"]
  peer_asn                  = aws_vpn_gateway.vpn_gw.amazon_side_asn
  interface                 = google_compute_router_interface.interface[each.key].name
  advertised_route_priority = 100
}

# -----------------------------------------------------------------------------
# IAM role & instance profile (SSM access, no SSH keys)
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
# Security groups (chained: GCP LB ranges -> NLB -> app instances)
# -----------------------------------------------------------------------------
module "nlb_sg" {
  source = "./modules/aws/security-groups"
  name   = "nlb-sg"
  vpc_id = module.aws_vpc.vpc_id

  ingress_rules = [
    {
      description     = "HTTP from Google LB / health check ranges arriving over the VPN"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = var.gcp_lb_source_cidrs
    }
  ]

  egress_rules = [
    {
      description = "Forward to targets inside the VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  tags = {
    Name = "nlb-sg"
  }
}

module "app_sg" {
  source = "./modules/aws/security-groups"
  name   = "app-sg"
  vpc_id = module.aws_vpc.vpc_id

  ingress_rules = [
    {
      description     = "HTTP only from the NLB security group"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.nlb_sg.id]
      cidr_blocks     = []
    }
  ]

  egress_rules = [
    {
      description = "Egress for OS updates / package repositories via NAT"
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
# Internal NLB with a fixed private IP in each private subnet.
# The hybrid NEG needs stable IPs; ASG instance IPs and ALB node IPs are not.
# -----------------------------------------------------------------------------
locals {
  # .10 in each private subnet (e.g. 10.0.4.10, 10.0.5.10, 10.0.6.10)
  nlb_private_ips = [for cidr in var.private_subnets : cidrhost(cidr, 10)]

  hybrid_neg_endpoints = [
    for ip in local.nlb_private_ips : {
      ip_address = ip
      port       = 80
    }
  ]
}

module "internal_nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name_prefix                      = "int-nl"
  load_balancer_type               = "network"
  internal                         = true
  vpc_id                           = module.aws_vpc.vpc_id
  security_groups                  = [module.nlb_sg.id]
  create_security_group            = false
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.environment == "prod"

  subnet_mapping = [
    for i, cidr in var.private_subnets : {
      subnet_id            = module.aws_vpc.private_subnets[i]
      private_ipv4_address = cidrhost(cidr, 10)
    }
  ]

  listeners = {
    tcp_80 = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name_prefix          = "app-tg"
      backend_protocol     = "TCP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 30
      preserve_client_ip   = false # targets see NLB IPs, so app_sg can reference nlb_sg
      create_attachment    = false # attached via the ASG

      health_check = {
        enabled             = true
        protocol            = "HTTP"
        path                = "/"
        port                = "traffic-port"
        matcher             = "200"
        interval            = 10 # NLB only allows 10 or 30
        healthy_threshold   = 3  # NLB requires healthy == unhealthy
        unhealthy_threshold = 3
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-internal-nlb"
  })
}

# -----------------------------------------------------------------------------
# Launch template + ASG
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

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx curl

    # IMDSv2 metadata
    TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)
    INSTANCE_ID=$(hostname)
    AZ="unknown"
    if [ -n "$TOKEN" ]; then
      INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id || hostname)
      AZ=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")
    fi

    cat > /var/www/html/index.html <<HTML
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

    systemctl enable --now nginx
  EOF
  )
}

module "app_asg" {
  source                    = "./modules/aws/auto_scaling_group"
  name                      = "app-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 180
  force_delete              = true
  target_group_arns         = [module.internal_nlb.target_groups["app"].arn]
  vpc_zone_identifier       = module.aws_vpc.private_subnets
  launch_template_id        = module.aws_launch_template.id
  launch_template_version   = "$Latest"
}

# -----------------------------------------------------------------------------
# GCP external load balancer -> hybrid NEG -> AWS NLB private IPs (over VPN)
# -----------------------------------------------------------------------------
module "hybrid_neg" {
  source       = "./modules/gcp/network_endpoint_groups/hybrid_neg"
  project_id   = var.gcp_project_id
  name         = "hybrid-neg"
  network      = module.gcp_vpc.vpc_name
  subnetwork   = module.gcp_vpc.subnets["hybrid-neg-subnet"].name
  default_port = 80
  endpoints    = local.hybrid_neg_endpoints
  zone         = var.gcp_zone

  depends_on = [google_compute_router_peer.bgp_peer]
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