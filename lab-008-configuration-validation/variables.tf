variable "rg_name" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition = (
      var.environment == "dev" ||
      var.environment == "staging" ||
      var.environment == "prod"
    )
    error_message = "environment input value must be dev, staging or prod"
  }
}

variable "location" {
  type = string

  validation {
    condition = (
      var.location == "eastus2" ||
      var.location == "centralus"
    )
    error_message = "location variable value must be eastus2 or centralus"
  }
}

variable "vnet_address_space" {
  type = string
}

variable "subnets" {
  type = map(object({
    name = string
    cidr = string
  }))
}
