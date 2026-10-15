output "id" {
  description = "The fully qualified ID of the created Internet NEG."
  value       = var.is_global ? google_compute_global_network_endpoint_group.global_neg[0].id : google_compute_region_network_endpoint_group.regional_neg[0].id
}

output "self_link" {
  description = "The self-link URI of the created Internet NEG."
  value       = var.is_global ? google_compute_global_network_endpoint_group.global_neg[0].self_link : google_compute_region_network_endpoint_group.regional_neg[0].self_link
}

output "name" {
  description = "The name identifier of the created Internet NEG."
  value       = var.is_global ? google_compute_global_network_endpoint_group.global_neg[0].name : google_compute_region_network_endpoint_group.regional_neg[0].name
}
