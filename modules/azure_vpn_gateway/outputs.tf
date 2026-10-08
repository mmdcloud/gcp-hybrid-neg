output "vpn_gateway_id" {
  value       = azurerm_virtual_network_gateway.vpn_gw.id
  description = "Resource ID of the Azure Virtual Network Gateway."
}

output "vpn_gateway_name" {
  value       = azurerm_virtual_network_gateway.vpn_gw.name
  description = "Name of the Azure Virtual Network Gateway."
}

output "public_ip_1" {
  value       = azurerm_public_ip.pip_1.ip_address
  description = "Public IP address of Azure Virtual Network Gateway Instance 0."
}

output "public_ip_2" {
  value       = azurerm_public_ip.pip_2.ip_address
  description = "Public IP address of Azure Virtual Network Gateway Instance 1."
}

output "connection_1_id" {
  value       = azurerm_virtual_network_gateway_connection.conn_1.id
  description = "Resource ID of Azure to GCP Connection 1."
}

output "connection_2_id" {
  value       = azurerm_virtual_network_gateway_connection.conn_2.id
  description = "Resource ID of Azure to GCP Connection 2."
}

