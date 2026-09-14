output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "web_snet_id" {
  value = azurerm_subnet.web.id
}

output "app_snet_id" {
  value = azurerm_subnet.app.id
}

output "mgmt_snet_id" {
  value = azurerm_subnet.mgmt.id
}

output "existing_rg_location" {
  value = data.azurerm_resource_group.existing.location
}
