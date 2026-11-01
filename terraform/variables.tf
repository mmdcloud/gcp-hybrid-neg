# ==============================================================================
# Global & Shared Configuration
# ==============================================================================

variable "tags" {
  type        = map(string)
  description = "Resource tags applied to AWS resources."
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "aws-to-gcp-hybrid-lb"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region (must match the AZs in var.azs)."
  default     = "us-east-1"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
  default     = "us-central1"
}

variable "gcp_zone" {
  type        = string
  description = "GCP Zone for zonal resources such as Hybrid NEGs."
  default     = "us-central1-a"
}

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment name. 'prod' enables NLB deletion protection."
}

variable "gcp_lb_source_cidrs" {
  type = list(string)
  default = [
    "34.96.0.0/20",    # Envoy-based global external Application LB proxies / probes
    "34.127.192.0/18", # Envoy-based global external Application LB proxies / probes
    "35.191.0.0/16",   # Classic health check probes
    "130.211.0.0/22"   # Classic health check probes
  ]
  description = "Google LB and health check source ranges. Allowed into the NLB SG and advertised from Cloud Router over BGP."
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the web servers."
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets. The NLB gets a static IP (.10) in each."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to deploy into"
}