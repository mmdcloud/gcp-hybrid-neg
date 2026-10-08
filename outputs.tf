# ==============================================================================
# Azure Outputs
# ==============================================================================

output "azure_resource_group" {
  value       = module.azure_vnet.resource_group_name
  description = "Azure Resource Group containing the VPN and network resources."
}

output "azure_vnet_id" {
  value       = module.azure_vnet.vnet_id
  description = "Resource ID of the Azure Virtual Network."
}

output "azure_workload_subnet_cidr" {
  value       = module.azure_vnet.workload_subnet_cidr
  description = "CIDR range of the Azure Workload Subnet."
}

output "azure_vpn_gateway_id" {
  value       = module.azure_vpn_gateway.vpn_gateway_id
  description = "Resource ID of the Azure Virtual Network Gateway."
}

output "azure_vpn_gateway_public_ip_1" {
  value       = module.azure_vpn_gateway.public_ip_1
  description = "Public IP Address of Azure VPN Gateway Instance 0."
}

output "azure_vpn_gateway_public_ip_2" {
  value       = module.azure_vpn_gateway.public_ip_2
  description = "Public IP Address of Azure VPN Gateway Instance 1."
}

output "azure_bgp_asn" {
  value       = var.azure_bgp_asn
  description = "Azure BGP ASN."
}

# ==============================================================================
# GCP Outputs
# ==============================================================================

output "gcp_vpc_id" {
  value       = module.gcp_vpc.network_id
  description = "Resource ID of the GCP VPC Network."
}

output "gcp_workload_subnet_cidr" {
  value       = module.gcp_vpc.subnet_cidr
  description = "CIDR range of the GCP Workload Subnetwork."
}

output "gcp_ha_vpn_gateway_id" {
  value       = module.gcp_ha_vpn.ha_vpn_gateway_id
  description = "Resource ID of the GCP Cloud HA VPN Gateway."
}

output "gcp_ha_vpn_gateway_ip_0" {
  value       = module.gcp_ha_vpn.ha_vpn_gateway_ip_0
  description = "Public IP Address of GCP HA VPN Gateway Interface 0."
}

output "gcp_ha_vpn_gateway_ip_1" {
  value       = module.gcp_ha_vpn.ha_vpn_gateway_ip_1
  description = "Public IP Address of GCP HA VPN Gateway Interface 1."
}

output "gcp_bgp_asn" {
  value       = var.gcp_bgp_asn
  description = "GCP Cloud Router BGP ASN."
}

# ==============================================================================
# Interconnect & BGP Peering Summary
# ==============================================================================

output "tunnel_1_peering" {
  value = {
    name                = "Tunnel 1 (Azure Inst 0 <-> GCP Int 0)"
    azure_public_ip     = module.azure_vpn_gateway.public_ip_1
    gcp_public_ip       = module.gcp_ha_vpn.ha_vpn_gateway_ip_0
    azure_bgp_apipa_ip  = var.azure_bgp_apipa_ip_1
    gcp_bgp_apipa_ip    = var.gcp_bgp_apipa_ip_1
    ipsec_shared_secret = "[SENSITIVE - See module.shared_secrets.tunnel_psk_1]"
  }
  description = "Configuration details for Tunnel 1."
}

output "tunnel_2_peering" {
  value = {
    name                = "Tunnel 2 (Azure Inst 1 <-> GCP Int 1)"
    azure_public_ip     = module.azure_vpn_gateway.public_ip_2
    gcp_public_ip       = module.gcp_ha_vpn.ha_vpn_gateway_ip_1
    azure_bgp_apipa_ip  = var.azure_bgp_apipa_ip_2
    gcp_bgp_apipa_ip    = var.gcp_bgp_apipa_ip_2
    ipsec_shared_secret = "[SENSITIVE - See module.shared_secrets.tunnel_psk_2]"
  }
  description = "Configuration details for Tunnel 2."
}

# ==============================================================================
# Optional Test VM Outputs
# ==============================================================================

output "azure_test_vm_private_ip" {
  value       = module.test_workloads.azure_test_vm_private_ip
  description = "Private IP of the Azure Test VM (if enabled)."
}

output "gcp_test_vm_private_ip" {
  value       = module.test_workloads.gcp_test_vm_private_ip
  description = "Private IP of the GCP Test VM (if enabled)."
}

# ==============================================================================
# Quick Verification CLI Commands
# ==============================================================================

output "verification_commands" {
  value = {
    azure_bgp_status  = "az network vnet-gateway list-bgp-peer-status --resource-group ${module.azure_vnet.resource_group_name} --name ${var.azure_vpn_gateway_name} -o table"
    azure_routes      = "az network vnet-gateway list-learned-routes --resource-group ${module.azure_vnet.resource_group_name} --name ${var.azure_vpn_gateway_name} -o table"
    gcp_tunnel_status = "gcloud compute vpn-tunnels list --project=${var.gcp_project_id} --filter=\"region:(${var.gcp_region})\""
    gcp_router_status = "gcloud compute routers get-status ${var.gcp_router_name} --region=${var.gcp_region} --project=${var.gcp_project_id}"
  }
  description = "Useful CLI commands for checking VPN and BGP operational status post-deployment."
}
