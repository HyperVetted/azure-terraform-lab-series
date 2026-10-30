variable "resource_group_name" {
  description = "Name of an existing Resource Group where the lab NSG will be deployed."
  type        = string
}

data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "main" {
  name                = "lab-013-nsg"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  tags = {
    owner   = "terraform"
    purpose = "drift-lab"
  }
}

output "nsg_id" {
  value = azurerm_network_security_group.main.id
}
