# ==============================================================================
# EC2 Instance Core Variables
# ==============================================================================

variable "name" {
  description = "Name tag applied to the EC2 instance and associated resources."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to deploy."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type (e.g. t3.micro, t3.small, m5.large)."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The key pair name to attach to the instance (null for bastionless SSM access)."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch the instance in."
  type        = string
}

variable "private_ip" {
  description = "Static private IP address to associate with the instance in the subnet."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IPv4 address to the instance in VPC."
  type        = bool
  default     = false
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "Alias for vpc_security_group_ids."
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "The IAM instance profile name to associate with the instance."
  type        = string
  default     = null
}

variable "instance_profile" {
  description = "Alias for iam_instance_profile."
  type        = string
  default     = null
}

variable "user_data" {
  description = "The user data script to run on boot."
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data."
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "When set to true, forces instance recreation when user_data changes."
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized."
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "If true, enables detailed CloudWatch monitoring (1-minute intervals)."
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Controls if traffic is checked for source/destination IP matching."
  type        = bool
  default     = true
}

variable "disable_api_termination" {
  description = "If true, enables EC2 termination protection against accidental deletion."
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance ('stop' or 'terminate')."
  type        = string
  default     = "stop"
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "instance_initiated_shutdown_behavior must be either 'stop' or 'terminate'."
  }
}

# ==============================================================================
# IMDSv2 (Instance Metadata Service) Variables
# ==============================================================================

variable "metadata_http_endpoint" {
  description = "Whether the metadata service is available ('enabled' or 'disabled')."
  type        = string
  default     = "enabled"
}

variable "metadata_http_tokens" {
  description = "Whether to require IMDSv2 session tokens ('required' or 'optional'). Defaults to 'required' for security."
  type        = string
  default     = "required"
  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be 'required' (IMDSv2) or 'optional' (IMDSv1)."
  }
}

variable "metadata_http_put_response_hop_limit" {
  description = "The desired HTTP PUT response hop limit for instance metadata requests (1-64)."
  type        = number
  default     = 1
}

variable "metadata_instance_metadata_tags" {
  description = "Enables access to instance tags from the metadata service ('enabled' or 'disabled')."
  type        = string
  default     = "enabled"
}

# ==============================================================================
# Root EBS Volume Variables
# ==============================================================================

variable "root_volume_type" {
  description = "Type of root EBS volume (e.g. gp3, gp2, io1, io2)."
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in gigabytes."
  type        = number
  default     = 20
}

variable "root_iops" {
  description = "IOPS provisioned for the root volume (only valid for gp3, io1, io2)."
  type        = number
  default     = 3000
}

variable "root_throughput" {
  description = "Throughput in MiB/s for the root volume (only valid for gp3, max 1000 MiB/s)."
  type        = number
  default     = 125
}

variable "root_encrypted" {
  description = "Whether to encrypt the root volume at rest."
  type        = bool
  default     = true
}

variable "root_kms_key_id" {
  description = "KMS Key ARN to use for root EBS volume encryption (default uses AWS-managed key)."
  type        = string
  default     = null
}

variable "root_delete_on_termination" {
  description = "Whether the root volume should be deleted on instance termination."
  type        = bool
  default     = true
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
