# output "id" {
#   value = google_compute_region_network_endpoint_group.serverless_neg.id
# }

output "id" {
  description = "The fully qualified Terraform resource ID of the created neg (regional or global, whichever was created)."
  value = length(google_compute_global_network_endpoint_group.neg) > 0 ? (
  google_compute_global_network_endpoint_group.neg[0].id) : length(google_compute_network_endpoint_group.neg) > 0 ? google_compute_network_endpoint_group.neg[0].id : google_compute_region_network_endpoint_group.neg[0].id
}