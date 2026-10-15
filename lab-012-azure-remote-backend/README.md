# LAB-012 — Azure Remote Backend

**Phase:** 12 — Backends and Remote State

## Objective

Move an existing Terraform state from the local backend to **Azure Blob Storage** without recreating infrastructure. Then use `terraform init -reconfigure` to connect a separate working directory to the same remote state.

The lab also covers backend authentication, an incorrect state key, and state locking.

## Environment

- Terraform CLI, Azure CLI, and PowerShell
- One **existing Azure Resource Group** with Contributor access
- One Azure Storage Account in that Resource Group
- One private blob container for Terraform state
- One small Azure Virtual Network (VNet) for testing

The Resource Group and Storage Account are **not managed** by the Terraform configuration in this lab. No new Resource Group is required.

## Repository files

| File | Purpose |
| --- | --- |
| `providers.tf` | Terraform and AzureRM provider requirements |
| `variables.tf` | Existing Resource Group and VNet name inputs |
| `main.tf` | Resource Group data source and lab VNet |
| `outputs.tf` | VNet ID output |
| `backend.tf.example` | Template for the Azure remote backend |

The Terraform files are sanitized examples. Set environment-specific names locally.

## Procedure

### 1. Establish local state

Start in a dedicated lab directory with the example Terraform configuration. **Do not create `backend.tf` yet.**

Set `ARM_SUBSCRIPTION_ID`, `TF_VAR_resource_group_name`, and `TF_VAR_vnet_name` locally. Select a VNet name that does not already exist in the Resource Group.

```powershell
terraform init
terraform validate
terraform plan
terraform apply
terraform state list
```

Review the plan before applying. The first apply should create only the lab VNet. Confirm the resource binding exists in the local state, then save a protected backup of `terraform.tfstate` **outside the repository**.

### 2. Prepare the remote backend

In the existing Resource Group, prepare an Azure Storage Account and a **private** blob container. Select a dedicated, unused blob name such as `lab012.tfstate`.

For this exercise, account-key authentication is an option when permitted by policy. Supply the key through the `ARM_ACCESS_KEY` environment variable in the PowerShell session. **Never put a key in HCL, Git, or terminal output that will be shared.**

Resource Group **Contributor** permissions do not automatically provide Microsoft Entra blob data access. Entra-based backend access normally requires an appropriate storage data-plane role, such as **Storage Blob Data Contributor**. An account key provides much broader access and should be handled accordingly.

### 3. Migrate local state

Copy `backend.tf.example` to `backend.tf` and replace the Resource Group, Storage Account, container, and state-key placeholders with the lab values.

Predict whether the existing VNet should change. Then run:

```powershell
terraform init -migrate-state
terraform state list
terraform plan
```

**Expected:** Existing resource bindings are transferred to the remote state. With unchanged configuration and no drift, the plan reports no changes.

### 4. Reconfigure a second working directory

Create a second directory containing the same `.tf` configuration, including the correct `backend.tf`. **Do not copy `.terraform/` or any state files.**

In the second directory, run:

```powershell
terraform init -reconfigure
terraform state list
terraform plan
```

**Expected:** Terraform connects to the **existing** Azure state blob. The original VNet binding is visible without migrating a local state file. A normal `terraform init` would also initialize a brand-new directory; `-reconfigure` is used here to demonstrate its behavior explicitly.

### 5. Test an incorrect backend key

In the **second** directory only, change the backend `key` to a verified-unused test blob name. Run:

```powershell
terraform init -reconfigure
terraform state list
terraform plan
```

**Expected:** The new backend location does not contain the previous VNet binding. Terraform may plan to create a VNet that already exists in Azure.

**Do not apply this plan.** Restore the original state key, run `terraform init -reconfigure` again, and verify the original bindings return.

### 6. Observe state locking

With both directories pointing to the same **correct** remote state:

1. In one terminal, start an operation that acquires the state lock and leave it active.
2. In another terminal, attempt `terraform plan -lock-timeout=10s` against the same state.
3. Observe the lock-acquisition behavior. Cancel the first operation normally and verify access returns.

Do not force-unlock a currently active operation.

### 7. Verify and clean up

Check the final state addresses and plan from the correctly configured directory. If removing the test VNet, inspect `terraform plan -destroy` before approving `terraform destroy`.

Do not destroy a shared Resource Group or Storage Account as part of VNet cleanup. Protect or remove retained state and backups according to the lab environment's requirements. Clear temporary credential environment variables when finished.

## Migration vs. reconfiguration

| Command | Behavior |
| --- | --- |
| `terraform init -migrate-state` | Initializes the configured backend and migrates existing state from the previous backend when applicable |
| `terraform init -reconfigure` | Initializes the configured backend **without migrating** previous state |

Both use the backend currently configured in HCL. `-reconfigure` does **not** mean switching back to local state.

## Troubleshooting

**`403 AuthorizationPermissionMismatch` when listing blobs:** The identity used for blob data access may not have the required permissions. Resource Group Contributor alone does not grant Entra blob data permissions. Verify the authentication method and assigned data-plane role before retrying migration.

**Terraform proposes creating an existing resource after a backend change:** Verify the backend storage account, container, and `key`, then inspect `terraform state list`. Do not apply until the correct state bindings are available.

**State lock prevents an operation:** Check whether another Terraform operation is still active. `-lock-timeout` controls how long Terraform waits to acquire the lock, not how long an operation may hold it.

## Security

Do not commit Terraform state, `.terraform/`, real `.tfvars`, account keys, SAS tokens, credentials, or saved plans. Terraform state may contain sensitive values even when normal CLI output hides them.
