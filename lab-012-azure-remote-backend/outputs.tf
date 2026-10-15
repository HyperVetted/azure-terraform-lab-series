output "vnet_id" {
  description = "ID recorded by the provider for the lab VNet."
  value       = azurerm_virtual_network.lab.id
}
