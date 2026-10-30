# LAB-015 — Import Existing Azure Infrastructure

Import an Azure Network Security Group (NSG) created outside Terraform, without recreating it.

This lab uses one temporary NSG in an **existing Resource Group**. Terraform does not create or manage the Resource Group.

## Requirements

- Terraform 1.5+, AzureRM provider 4.x, Azure Portal or Azure CLI
- Permission to create and delete NSGs inside an existing Resource Group
- `Microsoft.Network` already registered in the subscription
- A separate lab directory with local Terraform state

Automatic resource-provider registration is disabled because the lab can run with Resource-Group-scoped permissions.

## Files

| File | Purpose |
| --- | --- |
| `provider.tf` | Terraform and AzureRM provider settings |
| `variables.tf` | Inputs for the existing Azure environment |
| `main.tf` | NSG resource declaration |
| `terraform.tfvars.example` | Example values to replace locally |
| `stages/02-import.tf.example` | Import block used during the import step |

## Lab steps

1. **Create the NSG in Azure Portal.** Choose a unique temporary name and an existing Resource Group. Do not attach it to a subnet or network interface. Record its name, location, and full Azure resource ID.
2. **Set the inputs.** Copy `terraform.tfvars.example` to `terraform.tfvars` and replace every sample value with your own. The name and location in HCL must match the existing NSG.
3. **Inspect the initial plan.** Run `terraform init`, `terraform fmt`, `terraform validate`, and `terraform plan`. With empty state, Terraform proposes creating the NSG. **Do not apply this plan.**
4. **Add the import block.** Copy `stages/02-import.tf.example` into the root as `import.tf`. Run `terraform plan` again. Review the import and fix configuration differences before applying; do not approve unexpected changes or replacement.
5. **Import and verify.** Run `terraform apply` only when the plan is safe. Check the new binding with `terraform state list` and confirm the same NSG still exists in Azure.
6. **Remove the import instruction.** Delete `import.tf` but keep `main.tf`. A new `terraform plan` should show no changes when Azure and HCL match.
7. **Clean up.** Review `terraform plan -destroy`. Only if it targets the temporary NSG, run `terraform destroy` and verify removal in Azure. **Do not delete the Resource Group.**

## Expected result

The existing NSG becomes managed through a state binding after the import is applied. Removing the completed import block does not remove that binding. Later resource changes can still update, replace, or destroy the NSG, so inspect plans before applying.

## Safety

Never publish Terraform state, real `.tfvars`, credentials, saved plans, or live subscription and resource IDs. The repository's `.gitignore` excludes local Terraform state and variable files. The import stage uses the `.tf.example` extension so it is not loaded until copied to a `.tf` file.
