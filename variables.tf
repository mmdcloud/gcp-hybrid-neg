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

variable "psk_length" {
  type        = number
  description = "Length of the auto-generated Pre-Shared Key (PSK)."
  default     = 32
}

variable "custom_psk_1" {
  type        = string
  description = "Optional override for Pre-Shared Key for Tunnel 1. If left blank, a secure random key is generated."
  default     = ""
  sensitive   = true
}

variable "custom_psk_2" {
  type        = string
  description = "Optional override for Pre-Shared Key for Tunnel 2. If left blank, a secure random key is generated."
  default     = ""
  sensitive   = true
}

# ==============================================================================
# Azure Configuration Variables
# ==============================================================================

variable "azure_create_resource_group" {
  type        = bool
  description = "Whether to create a new Azure Resource Group."
  default     = true
}

variable "azure_resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group."
  default     = "rg-hybrid-connectivity-prod"
}

variable "azure_location" {
  type        = string
  description = "Azure Region for all Azure resources."
  default     = "eastus"
}

variable "azure_vnet_name" {
  type        = string
  description = "Name of the Azure Virtual Network."
  default     = "vnet-azure-hybrid"
}

variable "azure_vnet_address_spaces" {
  type        = list(string)
  description = "CIDR block address spaces for Azure VNet."
  default     = ["10.100.0.0/16"]
}

variable "azure_gateway_subnet_cidr" {
  type        = string
  description = "CIDR block for the dedicated Azure GatewaySubnet (minimum /27)."
  default     = "10.100.255.0/24"
}

variable "azure_workload_subnet_name" {
  type        = string
  description = "Name of the Azure Workload Subnet."
  default     = "snet-azure-workload"
}

variable "azure_workload_subnet_cidr" {
  type        = string
  description = "CIDR block for the Azure Workload Subnet."
  default     = "10.100.1.0/24"
}

variable "azure_vpn_gateway_name" {
  type        = string
  description = "Name of the Azure Virtual Network Gateway."
  default     = "vgw-azure-hybrid-prod"
}

variable "azure_vpn_gateway_sku" {
  type        = string
  description = "SKU for the Azure Virtual Network Gateway (e.g. VpnGw2AZ, VpnGw2, VpnGw1AZ)."
  default     = "VpnGw2AZ"
}

variable "azure_vpn_gateway_generation" {
  type        = string
  description = "Generation of the Azure VPN Gateway (Generation1 or Generation2)."
  default     = "Generation2"
}

variable "azure_availability_zones" {
  type        = list(string)
  description = "Availability zones for Azure Public IPs."
  default     = ["1", "2", "3"]
}

variable "azure_bgp_asn" {
  type        = number
  description = "BGP Autonomous System Number (ASN) for Azure VPN Gateway."
  default     = 65515
}

variable "azure_bgp_apipa_ip_1" {
  type        = string
  description = "APIPA BGP IP address for Azure Gateway Instance 0 (Tunnel 1)."
  default     = "169.254.21.2"
}

variable "azure_bgp_apipa_ip_2" {
  type        = string
  description = "APIPA BGP IP address for Azure Gateway Instance 1 (Tunnel 2)."
  default     = "169.254.22.2"
}

# ==============================================================================
# GCP Configuration Variables
# ==============================================================================

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID."
}

variable "gcp_region" {
  type        = string
  description = "GCP Region for Cloud HA VPN and VPC resources."
  default     = "us-east1"
}

variable "gcp_network_name" {
  type        = string
  description = "Name of the GCP VPC Network."
  default     = "vpc-gcp-hybrid"
}

variable "gcp_routing_mode" {
  type        = string
  description = "VPC Routing Mode: GLOBAL or REGIONAL."
  default     = "GLOBAL"
}

variable "gcp_workload_subnet_name" {
  type        = string
  description = "Name of the GCP Workload Subnet."
  default     = "sb-gcp-workload"
}

variable "gcp_workload_subnet_cidr" {
  type        = string
  description = "CIDR block for the GCP Workload Subnet."
  default     = "10.200.1.0/24"
}

variable "gcp_enable_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs on GCP subnet."
  default     = true
}

variable "gcp_vpn_gateway_name" {
  type        = string
  description = "Name of the GCP Cloud HA VPN Gateway."
  default     = "ha-vpn-gcp-hybrid-prod"
}

variable "gcp_external_vpn_gateway_name" {
  type        = string
  description = "Name of the GCP External VPN Gateway."
  default     = "ext-gw-azure-vng"
}

variable "gcp_router_name" {
  type        = string
  description = "Name of the GCP Cloud Router."
  default     = "cr-gcp-hybrid-prod"
}

variable "gcp_bgp_asn" {
  type        = number
  description = "BGP Autonomous System Number (ASN) for GCP Cloud Router."
  default     = 65001
}

variable "gcp_bgp_apipa_ip_1" {
  type        = string
  description = "APIPA BGP IP address for GCP Cloud Router Interface 0 (Tunnel 1)."
  default     = "169.254.21.1"
}

variable "gcp_bgp_apipa_ip_2" {
  type        = string
  description = "APIPA BGP IP address for GCP Cloud Router Interface 1 (Tunnel 2)."
  default     = "169.254.22.1"
}

variable "gcp_bgp_advertise_mode" {
  type        = string
  description = "BGP advertisement mode: DEFAULT or CUSTOM."
  default     = "CUSTOM"
}

variable "gcp_bgp_advertised_groups" {
  type        = list(string)
  description = "Advertised groups for BGP (e.g. ['ALL_SUBNETS'])."
  default     = ["ALL_SUBNETS"]
}

variable "gcp_bgp_custom_advertised_ip_ranges" {
  type = list(object({
    range       = string
    description = optional(string)
  }))
  description = "List of custom IP ranges to advertise via BGP from GCP to Azure."
  default     = []
}

variable "gcp_tunnel_0_route_priority" {
  type        = number
  description = "BGP route priority (MED) advertised on Tunnel 0 (lower is preferred)."
  default     = 100
}

variable "gcp_tunnel_1_route_priority" {
  type        = number
  description = "BGP route priority (MED) advertised on Tunnel 1 (lower is preferred)."
  default     = 100
}

# ==============================================================================
# IPsec Policy Configuration
# ==============================================================================

variable "ipsec_dh_group" {
  type        = string
  description = "Diffie-Hellman Group for Phase 1 (DHGroup14, DHGroup24, ECP384)."
  default     = "DHGroup14"
}

variable "ipsec_ike_encryption" {
  type        = string
  description = "IKE Phase 1 Encryption algorithm (AES256, GCMAES256)."
  default     = "AES256"
}

variable "ipsec_ike_integrity" {
  type        = string
  description = "IKE Phase 1 Integrity algorithm (SHA256, SHA384)."
  default     = "SHA256"
}

variable "ipsec_encryption" {
  type        = string
  description = "IPsec Phase 2 Encryption algorithm (AES256, GCMAES256)."
  default     = "AES256"
}

variable "ipsec_integrity" {
  type        = string
  description = "IPsec Phase 2 Integrity algorithm (SHA256, SHA384)."
  default     = "SHA256"
}

variable "ipsec_pfs_group" {
  type        = string
  description = "PFS Group for Phase 2 (PFS2048, PFS14, PFS24, ECP384)."
  default     = "PFS2048"
}

variable "ipsec_sa_lifetime" {
  type        = number
  description = "IPsec SA lifetime in seconds."
  default     = 27000
}

variable "ipsec_sa_datasize" {
  type        = number
  description = "IPsec SA data size in KB."
  default     = 102400000
}

# ==============================================================================
# Optional Test Workloads Configuration
# ==============================================================================

variable "enable_test_vms" {
  type        = bool
  description = "Whether to provision test VMs in Azure and GCP to validate cross-cloud connectivity."
  default     = false
}

variable "test_vm_admin_username" {
  type        = string
  description = "Administrator username for test virtual machines."
  default     = "azureuser"
}

variable "test_vm_ssh_public_key" {
  type        = string
  description = "SSH public key content for test VM access."
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtV+q6b8t3d5YVqT2D1p4x5N3qE1M8h9bZ2w0vP1kLm hybrid-test-key"
}

variable "azure_test_vm_size" {
  type        = string
  description = "VM size for Azure test VM."
  default     = "Standard_B1s"
}

variable "gcp_test_vm_zone" {
  type        = string
  description = "Zone for GCP test VM."
  default     = "us-east1-b"
}

variable "gcp_test_vm_machine_type" {
  type        = string
  description = "Machine type for GCP test instance."
  default     = "e2-micro"
}

