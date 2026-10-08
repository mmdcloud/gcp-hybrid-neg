output "network_id" {
  value       = google_compute_network.vpc.id
  description = "Resource ID of the GCP VPC Network."
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "Name of the GCP VPC Network."
}

output "network_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "Self link of the GCP VPC Network."
}

output "subnet_id" {
  value       = google_compute_subnetwork.workload_subnet.id
  description = "Resource ID of the GCP workload subnetwork."
}

output "subnet_name" {
  value       = google_compute_subnetwork.workload_subnet.name
  description = "Name of the GCP workload subnetwork."
}

output "subnet_cidr" {
  value       = google_compute_subnetwork.workload_subnet.ip_cidr_range
  description = "CIDR range of the GCP workload subnetwork."
}

output "subnet_self_link" {
  value       = google_compute_subnetwork.workload_subnet.self_link
  description = "Self link of the GCP workload subnetwork."
}

