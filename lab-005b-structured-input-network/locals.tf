locals {
  vnet_name = "${var.project}-${var.environment}-vnet"
}

locals {
  web_snet_name = "${var.project}-${var.environment}-web-snet"
}

locals {
  app_snet_name = "${var.project}-${var.environment}-app-snet"
}

locals {
  mgmt_snet_name = "${var.project}-${var.environment}-mgmt-snet"
}

locals {
  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
