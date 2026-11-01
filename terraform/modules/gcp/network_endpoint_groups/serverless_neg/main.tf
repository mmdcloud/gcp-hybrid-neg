resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  network               = var.network
  subnetwork            = var.subnetwork

  dynamic "cloud_run" {
    for_each = var.cloud_run != null ? [var.cloud_run] : []
    content {
      service  = lookup(cloud_run.value, "service", null)
      tag      = lookup(cloud_run.value, "tag", null)
      url_mask = lookup(cloud_run.value, "url_mask", null)
    }
  }

  dynamic "cloud_function" {
    for_each = var.cloud_function != null ? [var.cloud_function] : []
    content {
      function = lookup(cloud_function.value, "function", null)
      url_mask = lookup(cloud_function.value, "url_mask", null)
    }
  }

  dynamic "app_engine" {
    for_each = var.app_engine != null ? [var.app_engine] : []
    content {
      service  = lookup(app_engine.value, "service", null)
      version  = lookup(app_engine.value, "version", null)
      url_mask = lookup(app_engine.value, "url_mask", null)
    }
  }
}
