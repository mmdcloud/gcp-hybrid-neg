resource "google_compute_global_network_endpoint_group" "global_neg" {
  count                 = var.is_global ? 1 : 0
  project               = var.project_id
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = "INTERNET_FQDN_PORT" # Automatically maps to FQDN or IP targets
}

# Attach endpoints to the Global Internet NEG
resource "google_compute_global_network_endpoint" "global_endpoints" {
  for_each = {
    for idx, ep in(var.is_global ? var.endpoints : []) :
    (ep.fqdn != null ? "${ep.fqdn}-${coalesce(ep.port, 443)}" : "${ep.ip_address}-${coalesce(ep.port, 443)}") => ep
  }

  project                       = var.project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.global_neg[0].name
  fqdn                          = each.value.fqdn
  ip_address                    = each.value.ip_address
  port                          = coalesce(each.value.port, 443) # Defaults to HTTPS 443
}

resource "google_compute_region_network_endpoint_group" "regional_neg" {
  count                 = var.is_global ? 0 : 1
  project               = var.project_id
  name                  = var.neg_name
  description           = var.description
  region                = var.region
  network_endpoint_type = "INTERNET_FQDN_PORT"
}

# Attach endpoints to the Regional Internet NEG
resource "google_compute_region_network_endpoint" "regional_endpoints" {
  for_each = {
    for idx, ep in(!var.is_global ? var.endpoints : []) :
    (ep.fqdn != null ? "${ep.fqdn}-${coalesce(ep.port, 443)}" : "${ep.ip_address}-${coalesce(ep.port, 443)}") => ep
  }

  project                       = var.project_id
  region                        = var.region
  region_network_endpoint_group = google_compute_region_network_endpoint_group.regional_neg[0].name
  fqdn                          = each.value.fqdn
  ip_address                    = each.value.ip_address
  port                          = coalesce(each.value.port, 443)
}
