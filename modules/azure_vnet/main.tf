/**
 * Module: azure_vnet
 * Purpose: Provisions Azure Resource Group, Virtual Network, GatewaySubnet, WorkloadSubnet,
 *          and Network Security Group with production-grade rules and tags.
 */

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = var.vnet_address_spaces
  tags                = var.tags
}

# Dedicated subnet for Azure VPN Gateway (Name must strictly be 'GatewaySubnet')
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# Workload subnet for resources in Azure
resource "azurerm_subnet" "workload_subnet" {
  name                 = var.workload_subnet_name
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.workload_subnet_cidr]
}

# Network Security Group for Workload Subnet
resource "azurerm_network_security_group" "workload_nsg" {
  name                = "${var.vnet_name}-workload-nsg"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-Inbound-GCP-VPC"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.gcp_allowed_cidr_ranges
    destination_address_prefix = var.workload_subnet_cidr
    description                = "Allow inbound traffic from GCP VPC subnets over VPN"
  }

  security_rule {
    name                       = "Allow-Inbound-VNet"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow intra-VNet communication"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload_nsg_assoc" {
  subnet_id                 = azurerm_subnet.workload_subnet.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}

