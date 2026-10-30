# LAB-011 — Terraform State Inspection

**Phase:** 11 — Terraform State  
**Type:** Read-only inspection of an existing Azure deployment  
**Status:** Completed on 2026-10-13 (learner-reported execution and follow-up verification)

This lab did **not** provision new infrastructure or create a new Terraform configuration. It inspected an existing deployment from LAB-006 and compared **HCL configuration, saved Terraform state, and actual Azure resources**.

## Goal

Understand how Terraform binds configuration resource addresses to real infrastructure, how to inspect those bindings, and why saved state is **not** a live Azure query.

## Prerequisites

- Existing LAB-006 deployment and its original Terraform working directory/state
- Terraform CLI and Azure CLI with read access to the existing Azure resource group/VNet
- PowerShell terminal
- Set the working directory to your own LAB-006 folder before running commands

This repository intentionally does **not** contain the original state file, subscription IDs, live environment-specific inputs, or Azure resource IDs.

## Procedure

### 1. Predict what state contains

Before running a command, predict:
- Total number of instance addresses
- Number of managed-resource instances versus data-source instances
- Expected resource instance addresses

### 2. List state addresses

```powershell
terraform state list
```

The completed LAB-006 inspection returned **5 instance addresses**:

```text
data.azurerm_resource_group.existing
data.azurerm_virtual_network.existing
azurerm_subnet.main["app"]
azurerm_subnet.main["db"]
azurerm_subnet.main["web"]
```

The two `data.` addresses represent read-only data-source instances. The three `azurerm_subnet.main[...]` addresses represent Terraform-managed subnet instances created with `for_each`.

### 3. Predict and inspect individual subnets

Before each command, predict what name, CIDR, ID, and other attributes might be present.

```powershell
terraform state show 'azurerm_subnet.main["web"]'
terraform state show 'azurerm_subnet.main["app"]'
terraform state show 'azurerm_subnet.main["db"]'
```

Compare each instance's stored values with the desired values in the LAB-006 configuration.

### 4. Inspect the entire saved state

```powershell
terraform show
```

This displays the locally recorded state. It does not independently verify what currently exists in Azure.

### 5. Compare with actual Azure

Supply your **own** existing LAB-006 resource-group and VNet names locally:

```powershell
$env:LAB_RG = "YOUR-EXISTING-RESOURCE-GROUP"
$env:LAB_VNET = "YOUR-EXISTING-VNET"

az network vnet subnet list `
  --resource-group $env:LAB_RG `
  --vnet-name $env:LAB_VNET `
  --query "[].{name:name,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes,id:id}" `
  --output json
```

Compare names and CIDRs across configuration, state, and Azure. Compare resource IDs **locally** without publishing subscription-specific identifiers. Azure API property names (for example, `addressPrefix`) need not match Terraform provider schema names (for example, `address_prefixes`) to represent the same CIDR.

### 6. Identify computed attributes

Inspect `id` in the state for a managed subnet. The Azure resource identifier is supplied by Azure and recorded by the AzureRM provider; it is **not** an argument authored in the subnet's HCL.

### 7. Check for proposed changes (read-only)

```powershell
terraform plan
```

**Observed/reported result:** The learner reported no planned changes after comparing the inspected subnets across HCL, state, and Azure. This is a report of the executed lab, not stored CLI output in this repository.

### 8. Explain lost-state consequences (do not test by deleting files)

If the state file were lost while the real subnets remained in Azure, Terraform would lose those resource bindings. With the same HCL still declaring the subnets, a normal plan could propose new creations rather than automatically adopting the existing Azure subnets. Apply could fail because of existing objects; the appropriate recovery involves restoring state or importing existing resources as applicable.

## Results and takeaways

| Check | Learner-reported finding |
| --- | --- |
| State addresses | 5 total |
| Managed instances | 3 subnets: app, db, web |
| Data-source instances | 2: resource group and virtual network |
| HCL / state / Azure values | Inspected subnet CIDRs matched |
| Computed attribute | Subnet `id`, provided by Azure and stored by provider |
| Normal plan | No changes proposed |

**Mental model:**

```text
HCL configuration = desired infrastructure
Terraform state   = persisted managed-resource bindings and recorded attributes
Azure             = actual infrastructure
```

`terraform state list` shows addresses; `terraform state show ADDRESS` shows one recorded instance; `terraform show` displays saved state. None of those inspection commands alone proves that Azure still matches saved state.

## Safety

This is strictly a **read-only lab**. Do not use `terraform apply`, `terraform destroy`, `terraform state mv`, or `terraform state rm` as part of the inspection. Never manually edit or delete a working state file to simulate failure.

Do not commit or upload:
- `terraform.tfstate`, `terraform.tfstate.*`, or state backups
- `.terraform/`
- Real `terraform.tfvars` or other secret-bearing variable files
- Saved plan files
- Azure subscription IDs, resource IDs, credentials, or secrets

State may contain sensitive values, regardless of whether normal CLI output redacts them.

## Scope

The configuration/resources inspected belong to the already completed **LAB-006**. This folder intentionally contains only documentation, not copied HCL or a duplicate deployment. The Phase 11 gate was a separate assessment completed after the inspection lab.
