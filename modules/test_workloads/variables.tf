variable "enable_test_vms" {
  type        = bool
  description = "Whether to deploy lightweight test virtual machines in Azure and GCP to verify end-to-end connectivity."
  default     = false
}

variable "admin_username" {
  type        = string
  description = "Administrator username for the test virtual machines."
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content for VM authentication."
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtV+q6b8t3d5YVqT2D1p4x5N3qE1M8h9bZ2w0vP1kLm test-key"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name."
  default     = ""
}

variable "azure_location" {
  type        = string
  description = "Azure Region."
  default     = "eastus"
}

variable "azure_workload_subnet_id" {
  type        = string
  description = "Azure Workload Subnet ID."
  default     = ""
}

variable "azure_vm_size" {
  type        = string
  description = "Azure VM Size."
  default     = "Standard_B1s"
}

variable "azure_tags" {
  type        = map(string)
  description = "Tags for Azure resources."
  default     = {}
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID."
  default     = ""
}

variable "gcp_zone" {
  type        = string
  description = "GCP Zone."
  default     = "us-east1-b"
}

variable "gcp_workload_subnet_id" {
  type        = string
  description = "GCP Workload Subnet ID or Self Link."
  default     = ""
}

variable "gcp_machine_type" {
  type        = string
  description = "GCP Compute Engine machine type."
  default     = "e2-micro"
}

