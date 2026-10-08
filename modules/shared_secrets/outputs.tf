output "tunnel_psk_1" {
  value       = local.psk_1
  description = "Pre-Shared Key for IPsec Tunnel 1."
  sensitive   = true
}

output "tunnel_psk_2" {
  value       = local.psk_2
  description = "Pre-Shared Key for IPsec Tunnel 2."
  sensitive   = true
}

