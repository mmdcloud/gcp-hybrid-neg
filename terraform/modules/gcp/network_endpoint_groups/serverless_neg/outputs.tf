output "id" {
  description = "The fully qualified ID of the created Serverless NEG resource."
  value       = google_compute_region_network_endpoint_group.serverless_neg.id
}

output "self_link" {
  description = "The self-link URI of the created Serverless NEG resource."
  value       = google_compute_region_network_endpoint_group.serverless_neg.self_link
}

output "name" {
  description = "The name identifier of the created Serverless NEG resource."
  value       = google_compute_region_network_endpoint_group.serverless_neg.name
}