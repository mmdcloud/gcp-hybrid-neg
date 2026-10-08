output "azure_test_vm_private_ip" {
  value       = var.enable_test_vms ? azurerm_network_interface.azure_vm_nic[0].ip_configuration[0].private_ip_address : null
  description = "Private IP address of the Azure test virtual machine."
}

output "gcp_test_vm_private_ip" {
  value       = var.enable_test_vms ? google_compute_instance.gcp_test_vm[0].network_interface[0].network_ip : null
  description = "Private IP address of the GCP test compute instance."
}

