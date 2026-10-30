variable "rg_name" {
  description = "Existing Resource Group that contains the NSG."
  type        = string
}

variable "nsg_name" {
  description = "Name of the NSG created outside Terraform."
  type        = string
}

variable "location" {
  description = "Actual Azure region of the NSG."
  type        = string
}

variable "sub_id" {
  description = "Azure subscription GUID."
  type        = string
}

variable "nsg_id" {
  description = "Full Azure resource ID of the existing NSG, used by the import stage."
  type        = string
}
