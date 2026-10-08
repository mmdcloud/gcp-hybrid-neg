/**
 * Module: shared_secrets
 * Purpose: Generates strong, cryptographically secure Pre-Shared Keys (PSKs)
 *          for IPsec tunnels between Azure Virtual Network Gateway and GCP Cloud HA VPN.
 */

resource "random_password" "tunnel_psk_1" {
  length           = var.psk_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 4
}

resource "random_password" "tunnel_psk_2" {
  length           = var.psk_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 4
}

locals {
  psk_1 = var.custom_psk_1 != "" ? var.custom_psk_1 : random_password.tunnel_psk_1.result
  psk_2 = var.custom_psk_2 != "" ? var.custom_psk_2 : random_password.tunnel_psk_2.result
}

