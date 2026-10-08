output "ha_vpn_gateway_id" {
  value       = google_compute_ha_vpn_gateway.ha_gateway.id
  description = "Resource ID of the GCP Cloud HA VPN Gateway."
}

output "ha_vpn_gateway_name" {
  value       = google_compute_ha_vpn_gateway.ha_gateway.name
  description = "Name of the GCP Cloud HA VPN Gateway."
}

output "ha_vpn_gateway_ip_0" {
  value       = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[0].ip_address
  description = "Public IP address of GCP HA VPN Gateway Interface 0."
}

output "ha_vpn_gateway_ip_1" {
  value       = google_compute_ha_vpn_gateway.ha_gateway.vpn_interfaces[1].ip_address
  description = "Public IP address of GCP HA VPN Gateway Interface 1."
}

output "cloud_router_id" {
  value       = google_compute_router.router.id
  description = "Resource ID of the GCP Cloud Router."
}

output "cloud_router_name" {
  value       = google_compute_router.router.name
  description = "Name of the GCP Cloud Router."
}

output "tunnel_0_id" {
  value       = google_compute_vpn_tunnel.tunnel_0.id
  description = "Resource ID of GCP VPN Tunnel 0."
}

output "tunnel_1_id" {
  value       = google_compute_vpn_tunnel.tunnel_1.id
  description = "Resource ID of GCP VPN Tunnel 1."
}

