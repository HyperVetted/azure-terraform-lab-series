terraform {
  required_version = ">= 1.5.0"
}

resource "terraform_data" "local_probe" {
  input = "local-compare"
}

output "result" {
  value = terraform_data.local_probe.output
}
