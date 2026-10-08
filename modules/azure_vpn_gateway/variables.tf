variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group."
}

variable "location" {
  type        = string
  description = "Azure Region (e.g. eastus, westeurope)."
}

variable "vpn_gateway_name" {
  type        = string
  description = "Name of the Azure Virtual Network Gateway."
  default     = "vgw-azure-prod"
}

variable "gateway_subnet_id" {
  type        = string
  description = "Resource ID of the GatewaySubnet in Azure VNet."
}

variable "vpn_gateway_sku" {
  type        = string
  description = "SKU of the Azure VPN Gateway (e.g. VpnGw2AZ, VpnGw2, VpnGw1AZ, VpnGw1)."
  default     = "VpnGw2AZ"
}

variable "vpn_gateway_generation" {
  type        = string
  description = "Generation of the Azure VPN Gateway (Generation1 or Generation2)."
  default     = "Generation2"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the Public IPs (e.g. ['1', '2', '3'] or [] if not supported by region/SKU)."
  default     = ["1", "2", "3"]
}

variable "azure_bgp_asn" {
  type        = number
  description = "BGP Autonomous System Number (ASN) for Azure Virtual Network Gateway."
  default     = 65515
}

variable "azure_bgp_apipa_ip_1" {
  type        = string
  description = "Custom APIPA BGP IP address for Azure Gateway Instance 0."
  default     = "169.254.21.2"
}

variable "azure_bgp_apipa_ip_2" {
  type        = string
  description = "Custom APIPA BGP IP address for Azure Gateway Instance 1."
  default     = "169.254.22.2"
}

variable "gcp_vpn_gateway_ip_0" {
  type        = string
  description = "Public IP address of GCP HA VPN Gateway Interface 0."
}

variable "gcp_vpn_gateway_ip_1" {
  type        = string
  description = "Public IP address of GCP HA VPN Gateway Interface 1."
}

variable "gcp_bgp_asn" {
  type        = number
  description = "BGP ASN configured on GCP Cloud Router."
  default     = 65001
}

variable "gcp_bgp_apipa_ip_1" {
  type        = string
  description = "BGP APIPA IP address for GCP Cloud Router Interface 0."
  default     = "169.254.21.1"
}

variable "gcp_bgp_apipa_ip_2" {
  type        = string
  description = "BGP APIPA IP address for GCP Cloud Router Interface 1."
  default     = "169.254.22.1"
}

variable "tunnel_psk_1" {
  type        = string
  description = "Pre-Shared Key for Tunnel 1."
  sensitive   = true
}

variable "tunnel_psk_2" {
  type        = string
  description = "Pre-Shared Key for Tunnel 2."
  sensitive   = true
}

# Cryptographic IPSec Policy Parameters (Production Defaults)
variable "ipsec_dh_group" {
  type        = string
  description = "Diffie-Hellman Group for Phase 1 (e.g. DHGroup14, DHGroup24, ECP384)."
  default     = "DHGroup14"
}

variable "ipsec_ike_encryption" {
  type        = string
  description = "IKE Phase 1 Encryption algorithm (e.g. AES256, GCMAES256)."
  default     = "AES256"
}

variable "ipsec_ike_integrity" {
  type        = string
  description = "IKE Phase 1 Integrity algorithm (e.g. SHA256, SHA384)."
  default     = "SHA256"
}

variable "ipsec_encryption" {
  type        = string
  description = "IPsec Phase 2 Encryption algorithm (e.g. AES256, GCMAES256)."
  default     = "AES256"
}

variable "ipsec_integrity" {
  type        = string
  description = "IPsec Phase 2 Integrity algorithm (e.g. SHA256, SHA384)."
  default     = "SHA256"
}

variable "ipsec_pfs_group" {
  type        = string
  description = "PFS Group for Phase 2 (e.g. PFS2048, PFS14, PFS24, ECP384)."
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

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

