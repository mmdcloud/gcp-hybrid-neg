variable "project_id" {
  type        = string
  description = "GCP Project ID."
}

variable "region" {
  type        = string
  description = "GCP Region (e.g. us-east1, us-central1, europe-west1)."
  default     = "us-east1"
}

variable "network_name" {
  type        = string
  description = "Name of the GCP VPC Network."
  default     = "vpc-gcp-prod"
}

variable "routing_mode" {
  type        = string
  description = "Network routing mode: REGIONAL or GLOBAL. GLOBAL is recommended for hybrid multi-region routing."
  default     = "GLOBAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be either REGIONAL or GLOBAL."
  }
}

variable "subnet_name" {
  type        = string
  description = "Name of the workload subnetwork."
  default     = "sb-workload-01"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range of the workload subnetwork."
  default     = "10.200.1.0/24"
}

variable "enable_flow_logs" {
  type        = bool
  description = "Whether to enable VPC Flow Logs on the subnetwork."
  default     = true
}

variable "azure_allowed_cidr_ranges" {
  type        = list(string)
  description = "List of Azure VNet CIDR ranges permitted to communicate with GCP workload subnet."
  default     = ["10.100.0.0/16"]
}

variable "firewall_target_tags" {
  type        = list(string)
  description = "Target network tags for the Azure inbound firewall rule (empty list applies to all instances)."
  default     = []
}

variable "enable_iap_ssh" {
  type        = bool
  description = "Whether to create a firewall rule allowing SSH via Google Cloud Identity-Aware Proxy."
  default     = true
}

