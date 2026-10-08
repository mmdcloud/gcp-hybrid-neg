/**
 * Module: gcp_vpc
 * Purpose: Provisions GCP VPC Network, Workload Subnetwork with Flow Logs,
 *          and Firewall Rules allowing cross-cloud VPN traffic.
 */

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode # "GLOBAL" or "REGIONAL"
  description             = "VPC network for GCP with hybrid multi-cloud VPN connectivity to Azure."
}

resource "google_compute_subnetwork" "workload_subnet" {
  name                     = var.subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Firewall rule allowing inbound traffic from Azure VNet CIDRs over VPN
resource "google_compute_firewall" "allow_from_azure" {
  name        = "${var.network_name}-allow-from-azure"
  project     = var.project_id
  network     = google_compute_network.vpc.name
  description = "Allow inbound traffic from Azure VNet subnets over VPN."

  allow {
    protocol = "all"
  }

  source_ranges = var.azure_allowed_cidr_ranges
  target_tags   = var.firewall_target_tags
}

# Firewall rule allowing SSH via Google Identity-Aware Proxy (IAP) for secure testing
resource "google_compute_firewall" "allow_iap_ssh" {
  count       = var.enable_iap_ssh ? 1 : 0
  name        = "${var.network_name}-allow-iap-ssh"
  project     = var.project_id
  network     = google_compute_network.vpc.name
  description = "Allow SSH from Identity-Aware Proxy (IAP) range."

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]
}

