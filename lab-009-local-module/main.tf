data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

module "network" {
  source = "./modules/network"

  vnet_name           = "lab009-vnet"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  address_space       = ["10.90.0.0/16"]
}
