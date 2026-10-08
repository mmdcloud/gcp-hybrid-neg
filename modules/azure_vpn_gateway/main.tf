/**
 * Module: azure_vpn_gateway
 * Purpose: Provisions Azure Virtual Network Gateway in Active-Active High Availability mode
 *          with BGP peering, APIPA addresses, Local Network Gateways for GCP endpoints,
 *          and hardened IKEv2 IPsec connections with cryptographic policies.
 */

# Public IP 1 for Azure Virtual Network Gateway (Instance 0)
resource "azurerm_public_ip" "pip_1" {
  name                = "${var.vpn_gateway_name}-pip-1"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

# Public IP 2 for Azure Virtual Network Gateway (Instance 1 - Active-Active HA)
resource "azurerm_public_ip" "pip_2" {
  name                = "${var.vpn_gateway_name}-pip-2"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

# Azure Active-Active Route-Based Virtual Network Gateway with BGP
resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = true
  enable_bgp          = true
  sku                 = var.vpn_gateway_sku
  generation          = var.vpn_gateway_generation
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.pip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.pip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  bgp_settings {
    asn = var.azure_bgp_asn

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses       = [var.azure_bgp_apipa_ip_1]
    }

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses       = [var.azure_bgp_apipa_ip_2]
    }
  }
}

# Local Network Gateway representing GCP HA VPN Gateway Interface 0
resource "azurerm_local_network_gateway" "gcp_gw_1" {
  name                = "${var.vpn_gateway_name}-lng-gcp-int0"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.gcp_vpn_gateway_ip_0
  tags                = var.tags

  bgp_settings {
    asn                 = var.gcp_bgp_asn
    bgp_peering_address = var.gcp_bgp_apipa_ip_1
  }
}

# Local Network Gateway representing GCP HA VPN Gateway Interface 1
resource "azurerm_local_network_gateway" "gcp_gw_2" {
  name                = "${var.vpn_gateway_name}-lng-gcp-int1"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.gcp_vpn_gateway_ip_1
  tags                = var.tags

  bgp_settings {
    asn                 = var.gcp_bgp_asn
    bgp_peering_address = var.gcp_bgp_apipa_ip_2
  }
}

# Azure to GCP IPsec Connection 1 (Azure Gateway Instance 0 -> GCP Interface 0)
resource "azurerm_virtual_network_gateway_connection" "conn_1" {
  name                       = "${var.vpn_gateway_name}-to-gcp-conn-1"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_gw_1.id
  shared_key                 = var.tunnel_psk_1
  enable_bgp                 = true
  dpd_timeout_seconds        = 45
  tags                       = var.tags

  custom_bgp_addresses {
    primary = var.azure_bgp_apipa_ip_1
  }

  ipsec_policy {
    dh_group         = var.ipsec_dh_group
    ike_encryption   = var.ipsec_ike_encryption
    ike_integrity    = var.ipsec_ike_integrity
    ipsec_encryption = var.ipsec_encryption
    ipsec_integrity  = var.ipsec_integrity
    pfs_group        = var.ipsec_pfs_group
    sa_lifetime      = var.ipsec_sa_lifetime
    sa_datasize      = var.ipsec_sa_datasize
  }
}

# Azure to GCP IPsec Connection 2 (Azure Gateway Instance 1 -> GCP Interface 1)
resource "azurerm_virtual_network_gateway_connection" "conn_2" {
  name                       = "${var.vpn_gateway_name}-to-gcp-conn-2"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_gw_2.id
  shared_key                 = var.tunnel_psk_2
  enable_bgp                 = true
  dpd_timeout_seconds        = 45
  tags                       = var.tags

  custom_bgp_addresses {
    secondary = var.azure_bgp_apipa_ip_2
  }

  ipsec_policy {
    dh_group         = var.ipsec_dh_group
    ike_encryption   = var.ipsec_ike_encryption
    ike_integrity    = var.ipsec_ike_integrity
    ipsec_encryption = var.ipsec_encryption
    ipsec_integrity  = var.ipsec_integrity
    pfs_group        = var.ipsec_pfs_group
    sa_lifetime      = var.ipsec_sa_lifetime
    sa_datasize      = var.ipsec_sa_datasize
  }
}

