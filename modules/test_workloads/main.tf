/**
 * Module: test_workloads
 * Purpose: Provisions lightweight Linux test instances in both Azure and GCP
 *          workload subnets to validate end-to-end hybrid VPN routing, latency,
 *          MTU, and throughput without public IP exposure.
 */

# Azure Test Virtual Machine
resource "azurerm_network_interface" "azure_vm_nic" {
  count               = var.enable_test_vms ? 1 : 0
  name                = "nic-azure-test-vm"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  tags                = var.azure_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.azure_workload_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azure_test_vm" {
  count                           = var.enable_test_vms ? 1 : 0
  name                            = "vm-azure-test"
  location                        = var.azure_location
  resource_group_name             = var.azure_resource_group_name
  size                            = var.azure_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  tags                            = var.azure_tags

  network_interface_ids = [
    azurerm_network_interface.azure_vm_nic[0].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# GCP Test Compute Instance
resource "google_compute_instance" "gcp_test_vm" {
  count        = var.enable_test_vms ? 1 : 0
  name         = "vm-gcp-test"
  project      = var.gcp_project_id
  zone         = var.gcp_zone
  machine_type = var.gcp_machine_type
  tags         = ["allow-iap-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.gcp_workload_subnet_id
    # No external access config -> strictly private IP routing
  }

  metadata = {
    ssh-keys               = "${var.admin_username}:${var.ssh_public_key}"
    block-project-ssh-keys = "false"
  }
}

