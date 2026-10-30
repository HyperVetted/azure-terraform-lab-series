variable "rg_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet" {
  type = map(object({
    name             = string
    address_prefixes = string
  }))
}
