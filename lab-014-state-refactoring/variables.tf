variable "resource_group_name" {
  description = "Name of an existing Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region of the existing Resource Group."
  type        = string
}

variable "nsg_name" {
  description = "Unique name for the temporary lab Network Security Group."
  type        = string
}
