output "id" {
  description = "The fully qualified ID of the created Zonal NEG."
  value       = google_compute_network_endpoint_group.zonal_neg.id
}

output "self_link" {
  description = "The self-link URI of the created Zonal NEG."
  value       = google_compute_network_endpoint_group.zonal_neg.self_link
}

output "name" {
  description = "The name identifier of the created Zonal NEG."
  value       = google_compute_network_endpoint_group.zonal_neg.name
}