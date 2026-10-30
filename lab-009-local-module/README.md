# LAB-009 — Small Azure Local Module

This lab practices the core mechanics of a **local Terraform child module** with one real Azure resource.

This repository entry reflects the exercise that was actually completed. It is **not** a literal refactor of an already-managed root resource into a module. Instead, the VNet was built directly inside a local child module so the module boundary could be practiced cleanly.

## What This Lab Builds

```text
Existing Azure Resource Group
        │
        └── root module
              │
              └── module "network"
                    │
                    └── Azure Virtual Network
```

The existing Resource Group is read with a data source. Terraform manages only the VNet created inside the child module.

## What This Lab Practices

- root module vs child module
- local module source: `./modules/network`
- explicit module inputs
- separate root and child variable scopes
- child provider requirement vs root provider configuration
- child resource creation
- child output exposure
- root reference to `module.network.vnet_id`
- module resource addresses in state
- breaking and repairing a module input interface

## Repository Structure

```text
lab-009-local-module/
├── README.md
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── modules/
    └── network/
        ├── variables.tf
        ├── main.tf
        └── outputs.tf
```

## Module Interface

The child accepts exactly four inputs:

```text
vnet_name            → string
resource_group_name  → string
location             → string
address_space        → list(string)
```

It exposes:

```text
vnet_id
```

The value flow is:

```text
root expression
→ module argument
→ child variable
→ child VNet resource
→ child output
→ root module reference
```

## Run the Lab

Supply the name of an existing Resource Group for the current PowerShell session:

```powershell
$env:TF_VAR_resource_group_name = "YOUR-EXISTING-RG-NAME"
```

Then initialize and validate:

```powershell
terraform fmt -recursive
terraform init
terraform validate
```

Review the plan before applying:

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

Inspect the exposed output and resource address:

```powershell
terraform output network_vnet_id
terraform state list
```

The VNet should appear under a module address such as:

```text
module.network.azurerm_virtual_network.this
```

## Break/Fix Exercise

Temporarily rename the root module argument `vnet_name` to `network_name` without changing the child variable declaration.

Run:

```powershell
terraform validate
```

Terraform should reject the unsupported argument. Restore `vnet_name` and validate again.

This demonstrates that the child module's declared variables define its input interface.

## Cleanup

Review the destroy plan and remove the lab VNet:

```powershell
terraform plan -destroy
terraform destroy
Remove-Item .\tfplan -ErrorAction SilentlyContinue
```

The existing Resource Group is not managed by this lab and should remain.

## Scope Note

The canonical study curriculum also includes reasoning about moving an **existing** resource from a root address into a module address and preserving identity with state-aware refactoring such as a `moved` block.

That was **not** the implementation used in this supplemental LAB-009 build, so this README does not claim that it was.

## Security

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Do not commit Azure credentials, secrets, or environment-specific sensitive values.
