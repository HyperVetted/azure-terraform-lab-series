output "vnet_name" {
  value = data.azurerm_virtual_network.existing.name
}

output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.subnet : key => subnet.id
  }
}
