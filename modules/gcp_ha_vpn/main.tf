/**
 * Module: gcp_ha_vpn
 * Purpose: Provisions Google Cloud HA VPN Gateway, Cloud Router with BGP,
 *          External VPN Gateway (referencing Azure Gateway IPs), VPN Tunnels (IKEv2),
 *          and BGP Peering interfaces.
 */

# GCP Cloud HA VPN Gateway (Provides 2 public IP interfaces)
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name        = var.vpn_gateway_name
  project     = var.project_id
  region      = var.region
  network     = var.network_id
  description = "GCP Cloud HA VPN Gateway for hybrid connectivity to Azure Virtual Network Gateway."
}

# External VPN Gateway in GCP representing Azure Active-Active VPN Gateway IPs
resource "google_compute_external_vpn_gateway" "external_gateway" {
  name            = var.external_vpn_gateway_name
  project         = var.project_id
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "External VPN Gateway representing Azure Active-Active Virtual Network Gateway."

  interface {
    id         = 0
    ip_address = var.azure_vpn_gateway_ip_0
  }

  interface {
    id         = 1
    ip_address = var.azure_vpn_gateway_ip_1
  }
}

# Cloud Router for dynamic BGP route exchange
resource "google_compute_router" "router" {
  name        = var.router_name
  project     = var.project_id
  region      = var.region
  network     = var.network_id
  description = "Cloud Router for dynamic BGP routing with Azure VPN Gateway."

  bgp {
    asn               = var.gcp_bgp_asn
    advertise_mode    = var.bgp_advertise_mode
    advertised_groups = var.bgp_advertise_mode == "CUSTOM" ? var.bgp_advertised_groups : null

    dynamic "advertised_ip_ranges" {
      for_each = var.bgp_custom_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = lookup(advertised_ip_ranges.value, "description", null)
      }
    }
  }
}

# VPN Tunnel 0: GCP Interface 0 -> Azure Public IP 0 (External Interface 0)
resource "google_compute_vpn_tunnel" "tunnel_0" {
  name                            = "${var.vpn_gateway_name}-tunnel-0"
  project                         = var.project_id
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.tunnel_psk_1
  router                          = google_compute_router.router.id
  ike_version                     = 2
  description                     = "HA VPN Tunnel 0 connecting GCP HA VPN Interface 0 to Azure Gateway Instance 0."
}

# VPN Tunnel 1: GCP Interface 1 -> Azure Public IP 1 (External Interface 1)
resource "google_compute_vpn_tunnel" "tunnel_1" {
  name                            = "${var.vpn_gateway_name}-tunnel-1"
  project                         = var.project_id
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.tunnel_psk_2
  router                          = google_compute_router.router.id
  ike_version                     = 2
  description                     = "HA VPN Tunnel 1 connecting GCP HA VPN Interface 1 to Azure Gateway Instance 1."
}

# Cloud Router Interface for Tunnel 0
resource "google_compute_router_interface" "if_0" {
  name       = "${var.router_name}-if-0"
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
  ip_range   = "${var.gcp_bgp_apipa_ip_1}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_0.name
}

# BGP Peer for Tunnel 0 (Peering with Azure Gateway Instance 0)
resource "google_compute_router_peer" "peer_0" {
  name                      = "${var.router_name}-peer-0"
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.router.name
  peer_ip_address           = var.azure_bgp_apipa_ip_1
  peer_asn                  = var.azure_bgp_asn
  interface                 = google_compute_router_interface.if_0.name
  advertised_route_priority = var.tunnel_0_advertised_route_priority
}

# Cloud Router Interface for Tunnel 1
resource "google_compute_router_interface" "if_1" {
  name       = "${var.router_name}-if-1"
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
  ip_range   = "${var.gcp_bgp_apipa_ip_2}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

# BGP Peer for Tunnel 1 (Peering with Azure Gateway Instance 1)
resource "google_compute_router_peer" "peer_1" {
  name                      = "${var.router_name}-peer-1"
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.router.name
  peer_ip_address           = var.azure_bgp_apipa_ip_2
  peer_asn                  = var.azure_bgp_asn
  interface                 = google_compute_router_interface.if_1.name
  advertised_route_priority = var.tunnel_1_advertised_route_priority
}

