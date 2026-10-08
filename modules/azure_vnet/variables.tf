variable "create_resource_group" {
  type        = bool
  description = "Whether to create a new resource group or use an existing one."
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group."
}

variable "location" {
  type        = string
  description = "Azure Region (e.g. eastus, westeurope)."
  default     = "eastus"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Azure Virtual Network."
  default     = "vnet-azure-prod"
}

variable "vnet_address_spaces" {
  type        = list(string)
  description = "Address space for the Azure Virtual Network."
  default     = ["10.100.0.0/16"]
}

variable "gateway_subnet_cidr" {
  type        = string
  description = "CIDR block for the GatewaySubnet (minimum /27, recommended /24)."
  default     = "10.100.255.0/24"
}

variable "workload_subnet_name" {
  type        = string
  description = "Name of the workload subnet."
  default     = "snet-workload-01"
}

variable "workload_subnet_cidr" {
  type        = string
  description = "CIDR block for the workload subnet."
  default     = "10.100.1.0/24"
}

variable "gcp_allowed_cidr_ranges" {
  type        = list(string)
  description = "List of GCP VPC CIDR ranges permitted to communicate with Azure workload subnet."
  default     = ["10.200.0.0/16"]
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "azure-to-gcp-vpn"
  }
}

