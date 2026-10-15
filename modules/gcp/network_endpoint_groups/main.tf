resource "google_compute_global_network_endpoint_group" "neg" {
  count                 = var.type == "GLOBAL" ? 1 : 0
  name                  = var.neg_name
  description           = var.description
  default_port          = var.default_port
  network_endpoint_type = var.neg_type
}

resource "google_compute_network_endpoint_group" "neg" {
  count                 = var.type == "ZONAL" ? 1 : 0
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = var.neg_type
  network               = var.network
  subnetwork            = var.subnetwork
  default_port          = var.default_port
  zone                  = var.zone
}

resource "google_compute_region_network_endpoint_group" "neg" {
  count                 = var.type == "REGIONAL" ? 1 : 0
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = var.neg_type
  region                = var.location
  network               = var.network
  subnetwork            = var.subnetwork

  dynamic "cloud_run" {
    for_each = var.cloud_run != null ? [var.cloud_run] : []
    content {
      service  = cloud_run.value.service
      tag      = cloud_run.value.tag
      url_mask = cloud_run.value.url_mask
    }
  }

  dynamic "cloud_function" {
    for_each = var.cloud_function != null ? [var.cloud_function] : []
    content {
      function = cloud_function.value.function
      url_mask = cloud_function.value.url_mask
    }
  }

  dynamic "app_engine" {
    for_each = var.app_engine != null ? [var.app_engine] : []
    content {
      service  = app_engine.value.service
      version  = app_engine.value.version
      url_mask = app_engine.value.url_mask
    }
  }

  dynamic "psc_data" {
    for_each = var.psc_data != null ? [var.psc_data] : []
    content {
      producer_port = psc_data.value.producer_port
    }
  }

  psc_target_service = var.psc_target_service
}
