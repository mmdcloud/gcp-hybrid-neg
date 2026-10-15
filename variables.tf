# ==============================================================================
# Global & Shared Configuration
# ==============================================================================

variable "tags" {
  type        = map(string)
  description = "Resource tags applied to Azure resources and labels where applicable."
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "azure-to-gcp-vpn"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-southeast-2"
}

variable "gcp_region" {
  type        = string
  description = "AWS Region"
  default     = "us-central-1"
}

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment name."
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID where resources will be deployed."
}

variable "alb_subnet_ids" {
  type        = list(string)
  description = "Private subnets for the internal ALB (minimum 2 AZs required)."
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Private subnets where ASG EC2 instances are launched."
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "Internal CIDR ranges allowed to query the ALB over port 80."
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the web servers."
}

variable "asg_min_size" {
  type        = number
  default     = 2
}

variable "asg_max_size" {
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  type        = number
  default     = 2
}