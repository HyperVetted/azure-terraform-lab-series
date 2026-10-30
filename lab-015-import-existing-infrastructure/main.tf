resource "azurerm_network_security_group" "existing" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.rg_name
}
