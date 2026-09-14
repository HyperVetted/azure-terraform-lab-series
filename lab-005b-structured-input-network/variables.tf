variable "rg_name" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "lab"
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_cidr" {
  type = list(list(string))
}
