data "azurerm_resource_group" "existing" {
  name = var.rg_name
}

resource "azurerm_virtual_network" "lab" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  address_space       = ["10.77.0.0/16", ]
  tags = {
    lab         = "007"
    managed_by  = "terraform"
    environment = "dev"
  }
}

resource "azurerm_subnet" "web" {
  name                 = "lab007-web-snet"
  address_prefixes     = ["10.77.1.0/24"]
  virtual_network_name = azurerm_virtual_network.lab.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

resource "azurerm_subnet" "app" {
  name                 = "lab007-app-snet"
  address_prefixes     = ["10.77.2.0/24"]
  virtual_network_name = azurerm_virtual_network.lab.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}
