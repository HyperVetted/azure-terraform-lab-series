# LAB-013 — Drift and Refresh

**Phase:** 13 — Drift and Refresh

## Objective

Deploy one Azure Network Security Group (NSG), intentionally modify a tag outside Terraform, compare normal planning with refresh-only operations, and reconcile the drift safely.

## Environment

- Terraform CLI, Azure CLI, and PowerShell / VS Code
- An existing, permitted Azure Resource Group (the lab does not create one)
- A fresh working directory with **local state**, isolated from other labs
- AzureRM provider v4.x

## Files

| File | Purpose |
| --- | --- |
| `provider.tf` | Terraform and AzureRM requirements / provider configuration |
| `main.tf` | Existing Resource Group data source, NSG, tags, and NSG ID output |

The configuration is reusable across Azure environments. Supply the existing Resource Group name through the `resource_group_name` variable; the NSG inherits that Resource Group's location. No state, credentials, or Azure resource IDs are included.

## Procedure

### 1. Deploy an isolated NSG

Use a new folder/state, and supply your own existing Resource Group name locally. For PowerShell:

```powershell
$env:TF_VAR_resource_group_name = "YOUR-EXISTING-RESOURCE-GROUP"
```

Set AzureRM authentication locally (for example, `az login` and an appropriate subscription selection). Do not store credentials or subscription-specific values in committed HCL.

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

**Predict before apply:** Only `azurerm_network_security_group.main` should be created. Inspect the plan; do not approve unrelated changes.

### 2. Create an out-of-band change

In Azure Portal, locate the newly deployed NSG and change only its `owner` tag from `terraform` to `admin`. Leave HCL unchanged.

```powershell
terraform plan
```

**Expected:** Refresh discovers the Azure tag value `admin`; the normal plan proposes an in-place tag update back to `terraform`. Planning alone does not change Azure or persist refreshed state.

### 3. Compare refresh-only behavior

```powershell
terraform plan -refresh-only
terraform apply -refresh-only
terraform state show azurerm_network_security_group.main
```

**Expected:** The refresh-only plan previews a saved-state update. After approving refresh-only apply, state records the actual `admin` tag while Azure stays `admin` and HCL still specifies `terraform`.

### 4. Reconcile infrastructure to HCL

```powershell
terraform plan
terraform apply
terraform plan
```

**Expected:** Normal apply restores Azure's `owner` tag to `terraform`. The subsequent plan shows no changes, assuming no other drift.

### 5. Clean up

```powershell
terraform plan -destroy
terraform destroy
terraform state list
```

**Safety:** Carefully inspect the destroy plan before approval. Only the dedicated NSG should be removed. Confirm deletion in Azure. Do not destroy or modify the existing shared Resource Group.

## Conceptual distinctions

| Mechanism | What it does |
| --- | --- |
| Out-of-band change | Modifies real infrastructure without Terraform |
| Drift | Real infrastructure differs from desired configuration |
| Normal `terraform plan` | Refreshes its working view and proposes Azure changes toward HCL |
| `terraform plan -refresh-only` | Proposes state changes toward actual infrastructure, without saving them |
| `terraform apply -refresh-only` | Persists refreshed state, without modifying Azure |
| Normal `terraform apply` | Performs approved infrastructure changes and saves resulting state |

**HCL = desired configuration; state = tracked bindings/known attributes; Azure = actual infrastructure.**

`ignore_changes` was deliberately not used in this lab: it would suppress the intended tag reconciliation during normal update planning.

## Security

Do not publish `terraform.tfstate`, state backups, `.terraform/`, saved plans, real `.tfvars`, credential files, Azure subscription IDs, full live resource IDs, or screenshots containing secrets. Review diffs before committing.
