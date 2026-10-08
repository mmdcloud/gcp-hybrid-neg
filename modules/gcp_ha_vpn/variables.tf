variable "project_id" {
  type        = string
  description = "GCP Project ID."
}

variable "region" {
  type        = string
  description = "GCP Region for HA VPN and Cloud Router."
}

variable "network_id" {
  type        = string
  description = "Resource ID or Self Link of the GCP VPC Network."
}

variable "vpn_gateway_name" {
  type        = string
  description = "Name of the GCP Cloud HA VPN Gateway."
  default     = "ha-vpn-gcp-prod"
}

variable "external_vpn_gateway_name" {
  type        = string
  description = "Name of the GCP External VPN Gateway."
  default     = "ext-gw-azure-vng"
}

variable "azure_vpn_gateway_ip_0" {
  type        = string
  description = "Public IP address of Azure Virtual Network Gateway Instance 0."
}

variable "azure_vpn_gateway_ip_1" {
  type        = string
  description = "Public IP address of Azure Virtual Network Gateway Instance 1."
}

variable "router_name" {
  type        = string
  description = "Name of the GCP Cloud Router."
  default     = "cr-gcp-prod"
}

variable "gcp_bgp_asn" {
  type        = number
  description = "BGP Autonomous System Number (ASN) for GCP Cloud Router."
  default     = 65001
}

variable "azure_bgp_asn" {
  type        = number
  description = "BGP ASN for Azure Virtual Network Gateway."
  default     = 65515
}

variable "gcp_bgp_apipa_ip_1" {
  type        = string
  description = "BGP APIPA IP address for GCP Cloud Router Interface 0 (without CIDR mask)."
  default     = "169.254.21.1"
}

variable "azure_bgp_apipa_ip_1" {
  type        = string
  description = "BGP APIPA IP address for Azure Gateway Instance 0."
  default     = "169.254.21.2"
}

variable "gcp_bgp_apipa_ip_2" {
  type        = string
  description = "BGP APIPA IP address for GCP Cloud Router Interface 1 (without CIDR mask)."
  default     = "169.254.22.1"
}

variable "azure_bgp_apipa_ip_2" {
  type        = string
  description = "BGP APIPA IP address for Azure Gateway Instance 1."
  default     = "169.254.22.2"
}

variable "tunnel_psk_1" {
  type        = string
  description = "Pre-Shared Key for Tunnel 0."
  sensitive   = true
}

variable "tunnel_psk_2" {
  type        = string
  description = "Pre-Shared Key for Tunnel 1."
  sensitive   = true
}

variable "bgp_advertise_mode" {
  type        = string
  description = "BGP advertisement mode: DEFAULT or CUSTOM."
  default     = "CUSTOM"
}

variable "bgp_advertised_groups" {
  type        = list(string)
  description = "Advertised groups for custom BGP mode (e.g. ['ALL_SUBNETS'])."
  default     = ["ALL_SUBNETS"]
}

variable "bgp_custom_advertised_ip_ranges" {
  type = list(object({
    range       = string
    description = optional(string)
  }))
  description = "List of custom IP ranges to advertise via BGP to Azure."
  default     = []
}

variable "tunnel_0_advertised_route_priority" {
  type        = number
  description = "Base route priority for routes advertised via Tunnel 0."
  default     = 100
}

variable "tunnel_1_advertised_route_priority" {
  type        = number
  description = "Base route priority for routes advertised via Tunnel 1."
  default     = 100
}

