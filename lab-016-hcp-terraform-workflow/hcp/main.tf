terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "YOUR_HCP_ORGANIZATION"

    workspaces {
      name = "lab-016-remote-compare"
    }
  }
}

variable "run_label" {
  description = "String configured as a Terraform variable in the HCP workspace"
  type        = string
}

resource "terraform_data" "remote_probe" {
  input = var.run_label
}

output "result" {
  value = terraform_data.remote_probe.output
}
