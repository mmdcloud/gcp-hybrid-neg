# Create the Zonal Network Endpoint Group
resource "google_compute_network_endpoint_group" "zonal_neg" {
  project               = var.project_id
  name                  = var.neg_name
  description           = var.description
  network               = var.network
  subnetwork            = var.subnetwork
  zone                  = var.zone
  network_endpoint_type = "GCE_VM_IP_PORT"
  default_port          = var.default_port
}

# Attach individual VM endpoints to the Zonal NEG
resource "google_compute_network_endpoint" "vm_endpoints" {
  project = var.project_id
  zone    = var.zone

  # Dynamically generate unique map keys for the loop (InstanceName-Port)
  for_each = {
    for idx, ep in var.endpoints : "${ep.instance}-${coalesce(ep.port, var.default_port)}" => ep
  }

  network_endpoint_group = google_compute_network_endpoint_group.zonal_neg.name
  instance               = each.value.instance
  ip_address             = each.value.ip_address # Can be null; defaults to VM's primary internal IP
  port                   = coalesce(each.value.port, var.default_port)
}