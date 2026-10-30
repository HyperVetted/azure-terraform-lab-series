output "vnet_id" {
  value = azurerm_virtual_network.lab.id
}

output "app_snet_id" {
  value = azurerm_subnet.app.id
}

output "web_snet_id" {
  value = azurerm_subnet.web.id
}
