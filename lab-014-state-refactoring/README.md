# LAB-014 — Terraform State Refactoring

Refactor an existing Azure Network Security Group (NSG) in Terraform **without recreating it**. This lab demonstrates resource renaming, moving a resource into a child module, and ending Terraform management while keeping the Azure resource.

The lab uses **one temporary NSG in an existing Azure Resource Group**. It does not create or delete the Resource Group.

## Prerequisites

- Terraform 1.7+, AzureRM provider 4.x, and Azure CLI
- Access to an existing Resource Group with permission to create and delete NSGs
- `Microsoft.Network` already registered in the subscription
- A separate working directory with isolated **local Terraform state**

The provider configuration disables automatic resource-provider registration, which avoids requiring subscription-level registration permissions. Azure Policy may still restrict NSG creation.

## What the lab covers

| Stage | Change | Expected result |
| --- | --- | --- |
| 1. Deploy | Create an NSG at `azurerm_network_security_group.legacy` | One NSG created and tracked in state |
| 2. Inspect an unsafe rename | Rename it to `.perimeter` in HCL **without** a `moved` block | Plan proposes create + destroy; **do not apply** |
| 3. Rename safely | Add a `moved` block for `.legacy` → `.perimeter` | State address changes; NSG stays intact |
| 4. Move into a module | Move the resource to `module.security.azurerm_network_security_group.perimeter` using another `moved` block | State address changes again; same Azure NSG |
| 5. Stop management | Remove the module call and use a `removed` block with `destroy = false` | State binding is removed; NSG remains in Azure |
| 6. Clean up | Delete **only the temporary NSG** through Azure CLI | NSG removed from Azure; existing RG untouched |

## Running the lab

The committed `main.tf` is the **initial deployable configuration**. Set `resource_group_name`, `location`, and a unique `nsg_name` using environment variables or a local `terraform.tfvars` based on `terraform.tfvars.example`.

Run the usual Terraform workflow: `terraform init`, `terraform validate`, `terraform plan`, and—after checking the plan—`terraform apply`. Use `terraform state list` to inspect the tracked resource address after each successful apply.

The `stages/` directory contains the configurations for the remaining steps:

- `02-rename-without-move.tf.example` — temporary **plan-only** demonstration
- `03-rename-with-move.tf.example` — safe address rename
- `04-move-to-module-root.tf.example` and `04-move-to-module-child.tf.example` — root configuration and child module
- `05-stop-management.tf.example` — remove the state binding without deleting the NSG

For each stage, use the relevant example as the **replacement** for root `main.tf`; for Stage 4, place the child example at `modules/security/main.tf`. Keep `provider.tf`, `variables.tf`, and the **same local state** throughout. Run `terraform init` again when adding the child module.

**Review every plan before applying.** In particular, never apply the unsafe create/destroy plan from Stage 2. The safe refactors should preserve the same NSG and its tags.

## Verification and cleanup

After the safe rename and module move, confirm the NSG still exists in Azure and that `terraform state list` shows the new address.

After applying the `removed` block, state should no longer track the NSG, but Azure should still contain it. Because Terraform no longer manages the resource, use Azure CLI to delete the **verified lab NSG**. Check its name, lab tag, and any attachments first. **Do not delete the existing Resource Group.**

## Safety

Never commit Terraform state, real `.tfvars`, credentials, saved plans, or resource IDs from your environment. State backups should be stored securely outside the repository. The stage files use the `.tf.example` extension so Terraform does not load them until you explicitly copy them into place.

**Key distinction:** Terraform configuration, state bindings, and Azure infrastructure are separate. Updating an address or removing a binding does not, by itself, delete the Azure resource.
