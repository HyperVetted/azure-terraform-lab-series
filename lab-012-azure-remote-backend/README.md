# LAB-012 — Azure Remote Backend

**Phase:** 12 — Backends and Remote State  
**Completed:** October 15, 2026 (my reported lab completion)

This was my first hands-on attempt at moving Terraform state from a local file into Azure Blob Storage. The main thing I wanted to understand was the difference between **moving state** and **just connecting Terraform to a backend**.

I'm still learning Terraform. This is a record of what I worked on and what tripped me up, not a production setup guide.

## My setup

- One existing Azure Resource Group where I have **Contributor** access
- An Azure Storage Account inside that same Resource Group
- A private blob container for the Terraform state
- A simple Azure VNet managed by Terraform
- PowerShell, Azure CLI, and Terraform on my computer

I did not create a new Resource Group. I also kept the Storage Account **outside** the Terraform configuration whose state I was migrating.

## What happened during the lab

1. Started with Terraform using local state for a small Azure resource.
2. Prepared an Azure Storage Account and a container to hold state.
3. Added an **azurerm backend** to the Terraform configuration.
4. Worked through **terraform init -migrate-state**, which is meant to transfer the existing bindings to the remote backend.
5. Practiced **terraform init -reconfigure** with another working directory to connect to state that was already there.
6. The runbook also included checking the state/plan, deliberately pointing to an unused state key **without applying**, restoring the correct key, and testing locking.

I reported the restarted lab complete on October 15. I did **not** save a full terminal transcript from the completed run, so the repository does not claim verified plan or lock-test output.

## The problem I actually ran into

My first attempt at migration stopped with:

~~~text
403 AuthorizationPermissionMismatch
~~~

At first I thought having Contributor on the Resource Group should be enough. It wasn't enough for **Entra-authenticated blob data access**.

I checked with Azure CLI using blob data authentication and got a permissions error too. We confirmed that Shared Key access was enabled on the Storage Account and that I could retrieve an account key.

I then decided to restart the lab and recreate the Storage Account. The restarted runbook used **Storage Account key authentication** instead of assuming I had Storage Blob Data Contributor rights.

**Lesson:** Permission to manage a Storage Account is not the same thing as permission to read its blobs using Entra ID. An access key is a different authentication method and has much broader access; I would prefer scoped blob RBAC where available.

## What finally made sense

| Command | What I use it for |
| --- | --- |
| `terraform init -migrate-state` | Initialize the configured backend **and transfer** the previous state |
| `terraform init -reconfigure` | Initialize the configured backend **without transferring** the previous state |

My earlier mistake was thinking `-reconfigure` meant going back to local state. It doesn't. Terraform uses the backend in the current HCL.

Another important point: if I point Terraform at a **different empty state key**, it loses access to the old resource bindings. A plan can then propose creating resources that already exist in Azure. That's why I should never apply blindly after a backend change.

## Files in this folder

These are **sanitized example files reconstructed from the lab requirements**, **not an exact upload of the HCL from my computer**:

- `providers.tf` — Terraform and AzureRM provider requirements
- `variables.tf` — inputs for an existing Resource Group and VNet name
- `main.tf` — existing RG data source and one lab VNet
- `outputs.tf` — VNet ID
- `backend.tf.example` — Azure Blob backend template, added only **after** local state exists

No live state, subscription IDs, storage keys, or actual Azure resource names are published here.

## Repeating the exercise

1. Set your Azure subscription ID using `ARM_SUBSCRIPTION_ID`, and supply the existing RG name and a unique VNet name through `TF_VAR_resource_group_name` and `TF_VAR_vnet_name`.
2. With **no active backend.tf**, run `terraform init`, review `terraform plan`, then `terraform apply` to create the test VNet with local state.
3. Inspect `terraform state list` and make a secure backup of local state outside Git.
4. Create or select an approved Storage Account and private blob container. Verify the chosen state key does not already exist.
5. Copy `backend.tf.example` to `backend.tf`, then replace the placeholders. Supply an approved Storage Account key through `ARM_ACCESS_KEY` **outside HCL**, if permitted.
6. Run `terraform init -migrate-state`. Check `terraform state list` and `terraform plan` before making any infrastructure changes.
7. In a second directory containing the same configuration but **no copied state or .terraform directory**, run `terraform init -reconfigure` with the same backend settings. Verify the bindings.
8. For the wrong-key exercise, use a confirmed-unused lab-only state key and **do not apply**. Restore the correct key and run `terraform init -reconfigure` again.
9. Test locking only in a controlled session. Never force-unlock an active operation. Review any destroy plan before cleanup.

## Takeaways

- **Provider:** talks to Azure to manage infrastructure.
- **Backend:** stores Terraform state.
- **Migration:** brings previous state bindings along.
- **Reconfiguration:** uses whatever state exists at the configured location.
- **Security:** Terraform state and Storage Account keys should never be committed to Git.

The Phase 12 gate is separate from completing this lab.
