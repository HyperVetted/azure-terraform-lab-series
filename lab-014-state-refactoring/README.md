# LAB-014 — State Refactoring with Azure

Refactor a managed Azure Network Security Group (NSG) without replacing the underlying resource. The workflow covers address renaming, moving a resource into a child module, and deliberately removing Terraform management while preserving Azure infrastructure.

**Scope:** One temporary NSG inside an **existing** Azure Resource Group. No Resource Group creation or deletion. Designed for environments with Resource Group–scoped Contributor permissions.

## Requirements

- Terraform CLI >= 1.7, Azure CLI, and PowerShell
- An existing Resource Group with permission to create and delete NSGs
- AzureRM provider 4.x; Azure CLI authentication to the intended subscription
- `Microsoft.Network` already registered at subscription scope (this configuration deliberately disables automatic provider registration)
- A fresh local working directory/state for this lab

Azure policies can still restrict NSG creation. All operations must be inspected before applying.

## Repository layout

| File | Role |
| --- | --- |
| `provider.tf` | Provider and Terraform requirements |
| `variables.tf` | Existing RG, location, and temporary NSG inputs |
| `main.tf` | Initial, deployable NSG configuration |
| `terraform.tfvars.example` | Optional sanitized input template |
| `stages/02-rename-without-move.tf.example` | Intentional address mismatch; **plan only** |
| `stages/03-rename-with-move.tf.example` | Safe rename with a `moved` block |
| `stages/04-move-to-module-root.tf.example` | Root module call and chained `moved` blocks |
| `stages/04-move-to-module-child.tf.example` | Child module's complete NSG configuration |
| `stages/05-stop-management.tf.example` | Declarative removal with `destroy = false` |

Stage files end in `.tf.example` so Terraform does not load them automatically. Copy **one** into root `main.tf` as directed, using the **same** working directory and state throughout. The other root `.tf` files remain unchanged.

## 1. Preflight and initial deployment

Open PowerShell inside `lab-014-state-refactoring`. Confirm the Azure subscription and enter an existing permitted Resource Group.

```powershell
az login
az account show --query "{subscription:name,id:id}" -o table

$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
$env:TF_VAR_resource_group_name = Read-Host "Existing Resource Group"
$env:TF_VAR_location = az group show --name $env:TF_VAR_resource_group_name --query location -o tsv
if (-not $env:TF_VAR_location) { throw "Resource Group inaccessible or location unavailable." }

$env:TF_VAR_nsg_name = "nsg-lab014-$([guid]::NewGuid().ToString('N').Substring(0,8))"
Write-Output "NSG: $env:TF_VAR_nsg_name"
```

Keep this PowerShell session open; later Azure CLI commands use the same values. Alternatively, copy `terraform.tfvars.example` to the Git-ignored `terraform.tfvars` file and populate the three variables locally. Do not use both mechanisms with conflicting values.

Initialize and inspect the creation plan:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
```

**Expected:** One NSG created at `azurerm_network_security_group.legacy`. The existing Resource Group is not managed by this configuration. Confirm the planned NSG name, location, and RG before applying.

```powershell
terraform apply
terraform state list
az network nsg show --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name --query "{name:name,location:location}" -o table
```

Verify the NSG exists. Save a protected state backup **outside this repository** before refactoring:

```powershell
$backupDir = Join-Path $HOME ".terraform-lab-backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item .\terraform.tfstate (Join-Path $backupDir "lab014-before-refactoring.tfstate.bak")
```

State can contain sensitive information; protect the backup as carefully as the original state.

## 2. Inspect an address mismatch — do not apply

Copy the deliberately unsafe rename into the working configuration:

```powershell
Copy-Item .\stages\02-rename-without-move.tf.example .\main.tf -Force
terraform plan
```

**Expected:** With the state still bound to `.legacy`, Terraform proposes a new `.perimeter` NSG and destruction of `.legacy`. This is an address mismatch, not a request to duplicate Azure infrastructure.

**Do not apply this plan.** No changes to Azure or persisted state result from this planning operation.

## 3. Rename safely with a `moved` block

```powershell
Copy-Item .\stages\03-rename-with-move.tf.example .\main.tf -Force
terraform fmt
terraform validate
terraform plan
```

**Expected:** Terraform recognizes `azurerm_network_security_group.legacy` → `azurerm_network_security_group.perimeter`. No NSG recreation or destruction should be planned; resource properties and tags are unchanged.

Only after confirming the plan is safe:

```powershell
terraform apply
terraform state list
```

**Expected state address:** `azurerm_network_security_group.perimeter`. Verify the original NSG still exists in Azure.

## 4. Move the NSG into a child module

Keep the same local state. Install the complete module configuration and replace root `main.tf`:

```powershell
New-Item -ItemType Directory -Force -Path .\modules\security | Out-Null
Copy-Item .\stages\04-move-to-module-child.tf.example .\modules\security\main.tf -Force
Copy-Item .\stages\04-move-to-module-root.tf.example .\main.tf -Force

terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

**Expected:** A state-address move from `.perimeter` to `module.security.azurerm_network_security_group.perimeter`, with no changes to the actual NSG. The two `moved` blocks preserve both original and intermediate addresses, supporting a chained migration.

Verify the plan contains no replacement, deletion, or unintended tag changes before applying:

```powershell
terraform apply
terraform state list
az network nsg show --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name --query name -o tsv
```

**Expected state address:** `module.security.azurerm_network_security_group.perimeter`. Azure still contains the same NSG.

## 5. Stop Terraform management without deleting Azure infrastructure

Remove the module call by replacing root `main.tf` with the final `removed` configuration. The child module files may remain in `modules/security` because that module is no longer called.

```powershell
Copy-Item .\stages\05-stop-management.tf.example .\main.tf -Force
terraform fmt
terraform validate
terraform plan
```

**Expected:** Terraform proposes to stop managing `module.security.azurerm_network_security_group.perimeter` with **`destroy = false`**. Confirm that the plan explicitly preserves the NSG in Azure. **Do not apply if the plan proposes a destroy.**

```powershell
terraform apply
terraform state list
az network nsg show --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name --query name -o tsv
terraform plan
```

**Expected:** No managed resource remains in Terraform state, while the same NSG still exists in Azure. The final plan should show no infrastructure changes.

The final configuration intentionally omits the previous `moved` blocks because this isolated workflow ends management. When migrating shared configurations used by multiple workspaces, coordinate `moved` history and any `removed` declarations across those workspaces before releasing a change.

## 6. Clean up the isolated NSG

After `removed` is applied, Terraform no longer tracks the NSG, so `terraform destroy` **cannot** remove it. Delete only the unique temporary NSG with Azure CLI after verifying its name and tag. Do not delete the Resource Group.

```powershell
if ($env:TF_VAR_nsg_name -notmatch '^nsg-lab014-[0-9a-f]{8}$') {
  throw "NSG name does not match the lab naming pattern."
}

$labTag = az network nsg show --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name --query "tags.lab" -o tsv
if ($labTag -ne "014") { throw "Unexpected lab tag. Stop." }

az network nsg show --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name --query "{name:name,id:id,subnets:subnets,interfaces:networkInterfaces}" -o json

$confirmation = Read-Host "Type DELETE to delete the verified lab NSG"
if ($confirmation -eq "DELETE") {
  az network nsg delete --resource-group $env:TF_VAR_resource_group_name --name $env:TF_VAR_nsg_name
}
```

If the NSG is attached to other infrastructure or has been repurposed, do not delete it. Confirm the NSG no longer exists by listing NSGs in the permitted Resource Group:

```powershell
az network nsg list --resource-group $env:TF_VAR_resource_group_name --query "[?name=='$env:TF_VAR_nsg_name'].name" -o tsv
```

Azure CLI's JMESPath quoting can vary with PowerShell interpolation. For an unambiguous final check, run `az network nsg show` with the same name; a resource-not-found result after successful deletion is expected.

## Behavior reference

| Operation | Persisted state | Azure NSG |
| --- | --- | --- |
| Rename without `moved` and run `plan` | Unchanged | Unchanged; unsafe create/destroy actions proposed |
| Rename with `moved` and apply | Address updated | Preserved |
| Move into module with `moved` and apply | Address updated | Preserved |
| Apply `removed` with `destroy = false` | NSG binding removed | Preserved |
| Delete NSG with Azure CLI after removal | No NSG binding | Deleted |

## Security and operational boundaries

- The Resource Group is an **input**, never a managed resource in this lab.
- Do not commit `terraform.tfvars`, `.terraform/`, state files/backups, saved plans, authentication tokens, resource IDs, or credentials.
- The repository's root `.gitignore` excludes Terraform state and real variable files; verify the staged Git diff before pushing.
- Keep isolated state: do not use another lab's Terraform working directory or shared backend.
- Inspect every plan before applying. In particular, **never apply** the intentionally unsafe plan in Step 2.
- Provider registration is disabled by design; deployment requires an already-registered `Microsoft.Network` provider and the necessary Resource Group permissions.

References: [Terraform `moved` refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) · [Remove from state using `removed`](https://developer.hashicorp.com/terraform/language/state/remove)
