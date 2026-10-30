variable "resource_group_name" {
  description = "Name of an existing resource group where this lab is permitted."
  type        = string
}

variable "vnet_name" {
  description = "A unique name for the test VNet in the existing resource group."
  type        = string
}
