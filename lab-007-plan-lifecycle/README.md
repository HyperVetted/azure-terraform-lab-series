# LAB-007 — Plan Interpretation and Resource Lifecycle

This lab focuses on predicting Terraform plan actions and observing lifecycle behavior against real Azure resources.

The lab uses an existing Azure Resource Group as a data source and creates dedicated LAB-007 networking resources inside it. The Resource Group is read by Terraform but is not managed by this lab's state.

The final publishable configuration in this directory is the clean baseline after all lifecycle experiments were reverted.

## What the Lab Builds

```text
Existing Azure Resource Group
        │
        └── LAB-007 Virtual Network: 10.77.0.0/16
                │
                ├── lab007-web-snet  10.77.1.0/24
                └── lab007-app-snet  10.77.2.0/24
```

Terraform manages the VNet and both subnets. The existing Resource Group remains external to this lab's managed resources.

## Learning Objectives

- read Terraform plan symbols and proposed actions
- distinguish create, update in place, destroy, and replacement
- predict plan behavior before running `terraform plan`
- separate configuration, Terraform state, and actual Azure infrastructure
- observe provider-specific replacement behavior
- use `prevent_destroy`
- use `ignore_changes`
- use `create_before_destroy`
- use `replace_triggered_by`
- return to a clean baseline after controlled experiments
- verify destroy and redeploy behavior with the same configuration

## Repository Structure

```text
lab-007-plan-lifecycle/
├── README.md
├── .terraform.lock.hcl
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars.example
```

| File | Purpose |
|---|---|
| `providers.tf` | Declares Terraform and AzureRM requirements |
| `variables.tf` | Defines the existing Resource Group and VNet name inputs |
| `main.tf` | Reads the existing RG and manages the LAB-007 VNet and subnets |
| `outputs.tf` | Exposes the managed VNet and subnet IDs |
| `terraform.tfvars.example` | Public-safe example values |
| `.terraform.lock.hcl` | Records the provider selection used by this working directory |
| `README.md` | Documents the lab baseline and experiments |

## Prerequisites

- Terraform CLI
- Azure CLI authentication
- access to an existing Azure Resource Group
- permission to create networking resources inside that Resource Group

Copy the example variable file and replace the Resource Group placeholder with the name of the existing RG used for the lab.

## Baseline Workflow

Initialize the isolated LAB-007 working directory:

```powershell
terraform init
```

Format and validate:

```powershell
terraform fmt
terraform validate
```

Before every plan, predict the expected action first:

```powershell
terraform plan
```

Apply the baseline only after reviewing the plan:

```powershell
terraform apply
```

After the initial apply, a second plan should show no infrastructure changes when configuration, state, and Azure agree.

## Plan Experiments

Each experiment followed the same cycle:

```text
make one configuration change
→ predict the plan
→ run terraform plan
→ inspect the result
→ explain the reason
→ revert the change
→ confirm a clean baseline
```

### Update in Place

A VNet tag value was changed to observe an in-place update.

### Replacement

The web subnet name was changed to observe a provider-required replacement rather than an in-place update.

### Create

A third subnet was temporarily added to configuration to observe a create action.

### Destroy

The app subnet resource was temporarily removed from configuration to observe Terraform proposing destruction of the managed instance recorded in state.

### Provider Behavior

The VNet address space was modified and the resulting plan was inspected rather than assuming every configuration change has the same lifecycle behavior.

## Lifecycle Experiments

### `prevent_destroy`

The web subnet was protected from destruction and then given a change that would normally require replacement. Terraform blocked the destructive action.

### `ignore_changes`

The VNet was configured to ignore tag changes. A tag difference was then introduced and the plan was inspected to confirm that the selected attribute was not reconciled.

### `create_before_destroy`

A replacement-triggering subnet change was combined with create-before-destroy behavior to inspect replacement ordering.

### `replace_triggered_by`

The app subnet was configured so a managed change to the VNet could trigger replacement of the subnet, demonstrating that lifecycle behavior can connect the replacement decision of one managed object to a change in another.

## Configuration, State, and Azure

This lab reinforces that these are separate things:

```text
configuration
≠
Terraform state
≠
actual Azure infrastructure
```

After `terraform destroy`:

- the Terraform configuration still exists
- the LAB-007 managed VNet and subnet instances are no longer bound in state
- the LAB-007 Azure networking resources no longer exist
- the existing Resource Group remains because it is only read as a data source

Running Terraform again with the same configuration causes Terraform to propose creation because configuration still declares the resources while state no longer contains those managed instances.

The lab was destroyed and then successfully redeployed to reinforce this behavior.

## Final Published Configuration

The checked-in `.tf` files represent the restored baseline, not one of the temporary lifecycle experiments.

This keeps the repository reproducible while the README records the behavioral experiments performed during the lab.

## Cleanup

Review the destroy plan before confirming cleanup:

```powershell
terraform plan -destroy
terraform destroy
```

The LAB-007 VNet and subnets are managed by this working directory. The existing Resource Group is a data source and is not intended to be destroyed by this configuration.

## Security

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Commit `terraform.tfvars.example` instead of the real environment-specific variable file.
