# LAB-010 — Registry Module

This lab practices consuming a **published Terraform Registry module** rather than writing the child module locally.

The focus is the module interface:

```text
Registry source
→ version constraint
→ documented inputs
→ published module internals
→ documented output
```

The public copy is sanitized so it does not contain a real Resource Group name, Terraform state, credentials, or environment-specific values.

## Module Used

```text
Azure/network/azurerm
```

The lab uses the module's 5.x line and finishes with:

```hcl
version = "~> 5.2"
```

This allows releases from 5.2.0 up to, but not including, 6.0.0.

The version exercise also compared:

```text
~> 5.2
→ >= 5.2.0 and < 6.0.0

~> 5.2.0
→ >= 5.2.0 and < 5.3.0
```

## What This Lab Practices

- Registry module source syntax
- module version constraints
- reading documented module inputs
- passing caller values into a published module
- consuming a documented module output
- `terraform init` module installation
- inspecting `.terraform/modules/`
- `terraform init -upgrade`
- separating Registry module versions from provider selections
- separating module version constraints from `.terraform.lock.hcl`

## Repository Structure

```text
lab-010-registry-module/
├── README.md
├── providers.tf
├── main.tf
└── outputs.tf
```

The configuration keeps the input declaration in `main.tf` so the public lab matches the small three-file shape used during the exercise.

## Provider Compatibility

The `Azure/network/azurerm` 5.x module requires AzureRM 3.x compatibility, so this lab is intentionally isolated from later labs that use AzureRM 4.x.

That is one reason each lab has its own Terraform working directory and state.

## Supply the Existing Resource Group

Set the existing Resource Group name for the current PowerShell session:

```powershell
$env:TF_VAR_resource_group_name = "YOUR-EXISTING-RG-NAME"
```

## Initialize and Validate

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
```

Before applying, inspect what the published module intends to create.

If you apply the lab:

```powershell
terraform apply
terraform output vnet_id
```

## Inspect Module Installation

After initialization, inspect:

```text
.terraform/modules/
```

Terraform downloads Registry module source code into its working data directory.

The caller does not edit that installed module as if it were local application code. The caller controls the module through its documented inputs and consumes its documented outputs.

## Version Upgrade Exercise

The exercise begins by selecting the 5.2.0 release, then broadens the allowed range to:

```hcl
version = "~> 5.2"
```

Run:

```powershell
terraform init -upgrade
```

Terraform can then select a newer Registry module release that still satisfies the constraint.

Important distinction:

```text
module version constraint
→ controls allowed Registry module releases

.terraform.lock.hcl
→ records selected provider versions
→ does not lock Registry module versions
```

## Cleanup

If the lab was applied:

```powershell
terraform plan -destroy
terraform destroy
```

The existing Resource Group is supplied to the Registry module and is not created by this root configuration.

## Security

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Do not publish Azure credentials, tokens, secrets, or environment-specific sensitive values.
