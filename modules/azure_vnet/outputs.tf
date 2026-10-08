output "resource_group_name" {
  value       = local.resource_group_name
  description = "Name of the Azure Resource Group."
}

output "resource_group_location" {
  value       = local.resource_group_location
  description = "Location of the Azure Resource Group."
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the Azure Virtual Network."
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the Azure Virtual Network."
}

output "gateway_subnet_id" {
  value       = azurerm_subnet.gateway_subnet.id
  description = "ID of the GatewaySubnet."
}

output "workload_subnet_id" {
  value       = azurerm_subnet.workload_subnet.id
  description = "ID of the Workload Subnet."
}

output "workload_subnet_cidr" {
  value       = var.workload_subnet_cidr
  description = "CIDR range of the Workload Subnet."
}

