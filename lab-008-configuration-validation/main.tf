data "azurerm_resource_group" "main" {
  name = var.rg_name
}

resource "azurerm_virtual_network" "main" {
  name                = "lab008-lab-vnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [var.vnet_address_space]

  lifecycle {
    precondition {
      condition     = startswith(data.azurerm_resource_group.main.name, "rg-")
      error_message = "resource group name must begin with rg-"
    }
  }
}

resource "azurerm_subnet" "main" {
  for_each             = var.subnets
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
  name                 = each.value.name
  address_prefixes     = [each.value.cidr]

  lifecycle {
    precondition {
      condition     = azurerm_virtual_network.main.location == "eastus2"
      error_message = "vnet location must be eastus2"
    }

    postcondition {
      condition     = endswith(self.name, "snet")
      error_message = "subnet name must end with snet"
    }
  }
}

check "snet_amt" {
  assert {
    condition     = length(keys(var.subnets)) == 2
    error_message = "there must be 2 subnets"
  }
}
