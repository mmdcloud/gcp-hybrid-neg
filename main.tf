# ----------------------------------------------------------------------------- 
# GCP Configuration
# -----------------------------------------------------------------------------
resource "random_password" "shared_secret_0" {
  length  = 32
  special = false
}

resource "random_password" "shared_secret_1" {
  length  = 32
  special = false
}

module "gcp_vpc" {
  source                          = "./modules/gcp/vpc"
  vpc_name                        = "gcp-vpc"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
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
  firewall_data = []
}

resource "google_compute_router" "router" {
  name    = "cr-ha-vpn"
  region  = var.gcp_region
  network = module.gcp_vpc.vpc_name

  bgp {
    asn            = 64514
    advertise_mode = "DEFAULT"
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
  vpc_id          = module.aws_vpc.id
  amazon_side_asn = 64512

  tags = {
    Name = "aws-vgw-gcp"
  }
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = module.aws_vpc.main_route_table_id
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

  tunnel1_inside_cidr   = "169.254.1.0/30"
  tunnel1_preshared_key = random_password.shared_secret_0.result
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

  tunnel1_inside_cidr   = "169.254.2.0/30"
  tunnel1_preshared_key = random_password.shared_secret_1.result
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
  shared_secret                   = random_password.shared_secret_0.result
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
  shared_secret                   = random_password.shared_secret_1.result
  router                          = google_compute_router.router.id
  ike_version                     = 2
}

resource "google_compute_router_interface" "router_interface_0" {
  name       = "cr-interface-0"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_0.name
}

resource "google_compute_router_interface" "router_interface_1" {
  name       = "cr-interface-1"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "169.254.2.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

resource "google_compute_router_peer" "bgp_peer_0" {
  name                      = "bgp-peer-0"
  router                    = google_compute_router.router.name
  region                    = var.gcp_region
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64512
  interface                 = google_compute_router_interface.router_interface_0.name
  advertised_route_priority = 100
}

resource "google_compute_router_peer" "bgp_peer_1" {
  name                      = "bgp-peer-1"
  router                    = google_compute_router.router.name
  region                    = var.gcp_region
  peer_ip_address           = "169.254.2.2"
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
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-sg-"
  description = "Controls traffic to the internal Application Load Balancer"
  vpc_id      = module.aws_vpc.id

  ingress {
    description = "HTTP ingress from allowed private networks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  egress {
    description = "Outbound traffic to target backend instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Backend App Security Group
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-sg-"
  description = "Allows traffic exclusively from the internal ALB"
  vpc_id      = module.aws_vpc.id

  ingress {
    description     = "HTTP traffic only from the ALB security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow egress for OS updates / package repositories via NAT/VPC endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# 4. INTERNAL APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------
resource "aws_lb" "internal" {
  name_prefix        = "int-lb-"
  internal           = true # Ensures the ALB gets private IPs only
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.environment}-internal-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name_prefix          = "app-tg-"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = module.aws_vpc.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------------------------------------------------------
# 5. LAUNCH TEMPLATE
# -----------------------------------------------------------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.app_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # Production IMDSv2 enforcement (Blocks SSRF credential abuse)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Cloud-init script configuring Nginx
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -xe
    dnf update -y
    dnf install -y nginx

    # Create custom dynamic landing page with instance metadata
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

    cat <<HTML > /usr/share/nginx/html/index.html
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

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-nginx-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.environment}-nginx-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# 6. AUTO SCALING GROUP
# -----------------------------------------------------------------------------
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.environment}-app-asg-"
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Delegates health checks to the ALB target group instead of just EC2 hypervisor status
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Performs rolling updates when the launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
    triggers = ["tag"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

module "hybrid_neg" {
  source     = "./modules/gcp/network_endpoint_groups/hybrid_neg"
  project_id = var.project_id
  name   = "hybrid-neg"
  network = module.gcp_vpc.vpc_name
  subnetwork = module.gcp_vpc.subnets["hybrid-neg-subnet"].name
  zone = "" 
}

module "gcp_lb" {
  source                   = "./modules/gcp/lb"
  project_id               = var.project_id
  name                     = "gcp-lb"
  load_balancer_type       = "EXTERNAL"
  region                   = var.gcp_region
  create_proxy_only_subnet = false

  backends = {
    lb = {
      is_default          = true
      protocol            = "HTTP"
      port_name           = "http"
      is_serverless_neg   = true
      manage_health_check = false
      groups = [
        { group = module.carshub_frontend_service_neg.id }
      ]
    }
  }
  enable_ssl              = false
  enable_http             = true
  managed_ssl_certificate = false
  enable_cloud_armor      = false
}