# Read the existing resource group. This configuration does NOT create it.
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "lab" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = ["10.212.0.0/16"]

  tags = {
    lab = "012"
  }
}
