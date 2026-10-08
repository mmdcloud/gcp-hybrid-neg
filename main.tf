/**
 * Root Module: Azure to GCP HA VPN Hybrid Interconnect
 * Purpose: End-to-end production-grade orchestration connecting Microsoft Azure
 *          to Google Cloud Platform using Active-Active Route-Based HA VPN with dynamic BGP.
 */

# 1. Cryptographic Secrets Management (IPsec PSKs)
module "shared_secrets" {
  source       = "./modules/shared_secrets"
  psk_length   = var.psk_length
  custom_psk_1 = var.custom_psk_1
  custom_psk_2 = var.custom_psk_2
}

# 2. Azure Virtual Network & Subnets
module "azure_vnet" {
  source                  = "./modules/azure_vnet"
  create_resource_group   = var.azure_create_resource_group
  resource_group_name     = var.azure_resource_group_name
  location                = var.azure_location
  vnet_name               = var.azure_vnet_name
  vnet_address_spaces     = var.azure_vnet_address_spaces
  gateway_subnet_cidr     = var.azure_gateway_subnet_cidr
  workload_subnet_name    = var.azure_workload_subnet_name
  workload_subnet_cidr    = var.azure_workload_subnet_cidr
  gcp_allowed_cidr_ranges = [var.gcp_workload_subnet_cidr]
  tags                    = var.tags
}

# 3. Google Cloud VPC Network & Workload Subnet
module "gcp_vpc" {
  source                    = "./modules/gcp_vpc"
  project_id                = var.gcp_project_id
  region                    = var.gcp_region
  network_name              = var.gcp_network_name
  routing_mode              = var.gcp_routing_mode
  subnet_name               = var.gcp_workload_subnet_name
  subnet_cidr               = var.gcp_workload_subnet_cidr
  enable_flow_logs          = var.gcp_enable_flow_logs
  azure_allowed_cidr_ranges = [var.azure_workload_subnet_cidr]
  enable_iap_ssh            = true
}

# 4. Azure Virtual Network Gateway (Active-Active HA with BGP)
module "azure_vpn_gateway" {
  source                 = "./modules/azure_vpn_gateway"
  resource_group_name    = module.azure_vnet.resource_group_name
  location               = module.azure_vnet.resource_group_location
  vpn_gateway_name       = var.azure_vpn_gateway_name
  gateway_subnet_id      = module.azure_vnet.gateway_subnet_id
  vpn_gateway_sku        = var.azure_vpn_gateway_sku
  vpn_gateway_generation = var.azure_vpn_gateway_generation
  availability_zones     = var.azure_availability_zones
  azure_bgp_asn          = var.azure_bgp_asn
  azure_bgp_apipa_ip_1   = var.azure_bgp_apipa_ip_1
  azure_bgp_apipa_ip_2   = var.azure_bgp_apipa_ip_2

  gcp_vpn_gateway_ip_0 = module.gcp_ha_vpn.ha_vpn_gateway_ip_0
  gcp_vpn_gateway_ip_1 = module.gcp_ha_vpn.ha_vpn_gateway_ip_1
  gcp_bgp_asn          = var.gcp_bgp_asn
  gcp_bgp_apipa_ip_1   = var.gcp_bgp_apipa_ip_1
  gcp_bgp_apipa_ip_2   = var.gcp_bgp_apipa_ip_2

  tunnel_psk_1 = module.shared_secrets.tunnel_psk_1
  tunnel_psk_2 = module.shared_secrets.tunnel_psk_2

  ipsec_dh_group       = var.ipsec_dh_group
  ipsec_ike_encryption = var.ipsec_ike_encryption
  ipsec_ike_integrity  = var.ipsec_ike_integrity
  ipsec_encryption     = var.ipsec_encryption
  ipsec_integrity      = var.ipsec_integrity
  ipsec_pfs_group      = var.ipsec_pfs_group
  ipsec_sa_lifetime    = var.ipsec_sa_lifetime
  ipsec_sa_datasize    = var.ipsec_sa_datasize

  tags = var.tags
}

# 5. Google Cloud HA VPN Gateway, Cloud Router & Tunnels
module "gcp_ha_vpn" {
  source                    = "./modules/gcp_ha_vpn"
  project_id                = var.gcp_project_id
  region                    = var.gcp_region
  network_id                = module.gcp_vpc.network_id
  vpn_gateway_name          = var.gcp_vpn_gateway_name
  external_vpn_gateway_name = var.gcp_external_vpn_gateway_name

  azure_vpn_gateway_ip_0 = module.azure_vpn_gateway.public_ip_1
  azure_vpn_gateway_ip_1 = module.azure_vpn_gateway.public_ip_2

  router_name                        = var.gcp_router_name
  gcp_bgp_asn                        = var.gcp_bgp_asn
  azure_bgp_asn                      = var.azure_bgp_asn
  gcp_bgp_apipa_ip_1                 = var.gcp_bgp_apipa_ip_1
  azure_bgp_apipa_ip_1               = var.azure_bgp_apipa_ip_1
  gcp_bgp_apipa_ip_2                 = var.gcp_bgp_apipa_ip_2
  azure_bgp_apipa_ip_2               = var.azure_bgp_apipa_ip_2
  tunnel_psk_1                       = module.shared_secrets.tunnel_psk_1
  tunnel_psk_2                       = module.shared_secrets.tunnel_psk_2
  bgp_advertise_mode                 = var.gcp_bgp_advertise_mode
  bgp_advertised_groups              = var.gcp_bgp_advertised_groups
  bgp_custom_advertised_ip_ranges    = var.gcp_bgp_custom_advertised_ip_ranges
  tunnel_0_advertised_route_priority = var.gcp_tunnel_0_route_priority
  tunnel_1_advertised_route_priority = var.gcp_tunnel_1_route_priority
}

# 6. Optional End-to-End Validation Test Virtual Machines
module "test_workloads" {
  source                    = "./modules/test_workloads"
  enable_test_vms           = var.enable_test_vms
  admin_username            = var.test_vm_admin_username
  ssh_public_key            = var.test_vm_ssh_public_key
  azure_resource_group_name = module.azure_vnet.resource_group_name
  azure_location            = module.azure_vnet.resource_group_location
  azure_workload_subnet_id  = module.azure_vnet.workload_subnet_id
  azure_vm_size             = var.azure_test_vm_size
  azure_tags                = var.tags
  gcp_project_id            = var.gcp_project_id
  gcp_zone                  = var.gcp_test_vm_zone
  gcp_workload_subnet_id    = module.gcp_vpc.subnet_id
  gcp_machine_type          = var.gcp_test_vm_machine_type
}
