output "neg_id" {
  description = "The ID of the created Hybrid NEG."
  value       = google_compute_network_endpoint_group.hybrid_neg.id
}

output "neg_self_link" {
  description = "The self-link of the created Hybrid NEG."
  value       = google_compute_network_endpoint_group.hybrid_neg.self_link
}

output "neg_name" {
  description = "The name of the created Hybrid NEG."
  value       = google_compute_network_endpoint_group.hybrid_neg.name
}