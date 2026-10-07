variable "resource_group_name" {
  type = string
}

module "network" {
  source  = "Azure/network/azurerm"
  version = "~> 5.2"

  resource_group_name = var.resource_group_name
  use_for_each        = true

  vnet_name       = "lab010-vnet"
  address_spaces  = ["10.100.0.0/16"]
  subnet_names    = ["lab010-subnet"]
  subnet_prefixes = ["10.100.1.0/24"]
}
