# Create the Hybrid Network Endpoint Group
resource "google_compute_network_endpoint_group" "hybrid_neg" {
  project               = var.project_id
  name                  = var.name
  network               = var.network
  subnetwork            = var.subnetwork
  zone                  = var.zone
  network_endpoint_type = "NON_GCP_PRIVATE_IP_PORT"
  default_port          = var.default_port
}

# Attach individual hybrid endpoints to the NEG
resource "google_compute_network_endpoint" "hybrid_endpoints" {
  project = var.project_id
  zone    = var.zone

  # Loop through the list of endpoints provided
  for_each = { for idx, endpoint in var.endpoints : "${endpoint.ip_address}-${coalesce(endpoint.port, var.default_port)}" => endpoint }

  network_endpoint_group = google_compute_network_endpoint_group.hybrid_neg.name
  ip_address             = each.value.ip_address
  port                   = coalesce(each.value.port, var.default_port)
}