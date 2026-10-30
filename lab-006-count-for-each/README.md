# LAB-006 — Multiple Azure Subnets with `count` and `for_each`

This lab compares Terraform resource instance identity under `count` and `for_each` by creating multiple Azure subnets inside an existing virtual network.

The lab is completed in two passes:

1. create the subnets with `count` and positional list inputs
2. refactor the configuration to `for_each` and keyed map inputs

The final publishable configuration in this directory is the `for_each` version.

## What the Lab Builds

The configuration reads existing Azure infrastructure and manages only the LAB-006 subnets.

```text
Existing Azure Resource Group
        │
        └── Existing Virtual Network: lab005b-lab-vnet
                │
                ├── lab006-web-snet  10.80.10.0/24
                ├── lab006-app-snet  10.80.20.0/24
                └── lab006-db-snet   10.80.30.0/24
```

The Resource Group and virtual network are data sources. They are read by Terraform but are not managed by this lab's state.

## Learning Objectives

- use `count` to create multiple resource instances
- use `count.index` with positional collections
- recognize numeric resource addresses such as `azurerm_subnet.subnet[0]`
- predict what happens when a list item is removed or reordered
- use `for_each` with a keyed collection
- use `each.key` and `each.value`
- access object properties with `each.value.property`
- recognize keyed resource addresses such as `azurerm_subnet.subnet["web"]`
- compare positional identity with keyed identity
- reason about configuration, state, and Azure infrastructure separately

## Repository Structure

```text
lab-006-count-for-each/
├── README.md
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars.example
```

| File | Purpose |
|---|---|
| `providers.tf` | Declares and configures the AzureRM provider |
| `variables.tf` | Defines the existing infrastructure names and keyed subnet input |
| `main.tf` | Reads the existing RG/VNet and creates the subnet instances with `for_each` |
| `outputs.tf` | Exposes the existing VNet name and keyed subnet IDs |
| `terraform.tfvars.example` | Public-safe example values |
| `README.md` | Documents the two-pass experiment and final configuration |

## Prerequisites

- Terraform CLI
- Azure CLI
- an Azure subscription
- Azure authentication
- an existing Resource Group
- an existing VNet with address space that contains the LAB-006 subnet prefixes

This lab was designed to reuse the VNet from LAB-005B rather than recreate or import it into a new Terraform state.

## Configure the Lab

Copy the example variable file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Update the Resource Group and VNet names if needed.

The final input structure is one map whose values are objects:

```hcl
subnet = {
  web = {
    name             = "lab006-web-snet"
    address_prefixes = "10.80.10.0/24"
  }

  app = {
    name             = "lab006-app-snet"
    address_prefixes = "10.80.20.0/24"
  }

  db = {
    name             = "lab006-db-snet"
    address_prefixes = "10.80.30.0/24"
  }
}
```

Its type declaration is:

```hcl
variable "subnet" {
  type = map(object({
    name             = string
    address_prefixes = string
  }))
}
```

The object blueprint is declared once. Every value stored in the map must follow that shape.

## Pass 1 — `count`

The first pass used two positional input collections: subnet names and subnet prefixes.

Conceptually:

```text
index 0 → web
index 1 → app
index 2 → db
```

The subnet resource used `count` and `count.index` to select the values for the current instance.

That produces numeric addresses such as:

```text
azurerm_subnet.subnet[0]
azurerm_subnet.subnet[1]
azurerm_subnet.subnet[2]
```

### The Identity Problem

With `count`, identity is tied to position.

If the middle list item is removed, the item that was previously at index `2` becomes the desired value at index `1`. Terraform therefore compares the new desired values against resources identified by those numeric addresses.

The important lesson is:

```text
count
→ identity by position/index
```

The exact Azure lifecycle action for a changed subnet also depends on which provider arguments changed. The key Terraform issue in this exercise is that positional addresses can shift when the collection changes.

Appending an item to the end is less disruptive because existing indexes remain unchanged and Terraform can add the new highest index.

## Transition Between Passes

The `count`-created LAB-006 subnets were destroyed before switching the same logical lab to `for_each`.

That kept the exercise focused on Phase 6 resource generation and identity behavior. Moving existing state addresses from numeric instances to keyed instances is a separate state-refactoring topic covered later in the lab series.

The existing Resource Group and VNet were data sources, so the cleanup was expected to target only the LAB-006 subnet resources managed by this working directory.

## Pass 2 — `for_each`

The final version replaces the parallel positional lists with one keyed map of objects:

```text
subnet
├── web → object
├── app → object
└── db  → object
```

The resource uses:

```hcl
for_each = var.subnet
```

For each resource instance:

```text
each.key
→ web / app / db

each.value
→ current subnet object

each.value.name
→ subnet name

each.value.address_prefixes
→ subnet CIDR string
```

The AzureRM subnet resource expects `address_prefixes` as a collection of strings, so the final configuration wraps the current object's CIDR string in a one-element list:

```hcl
address_prefixes = [each.value.address_prefixes]
```

The resulting Terraform addresses are keyed:

```text
azurerm_subnet.subnet["web"]
azurerm_subnet.subnet["app"]
azurerm_subnet.subnet["db"]
```

## Stable Identity

With `for_each`, identity is tied to the collection key rather than a list position.

If the `app` key is removed:

```text
azurerm_subnet.subnet["app"]
```

is the instance that disappears from configuration.

The `web` and `db` addresses do not shift.

Adding a new key such as `ops` creates a new keyed instance without changing the identities of the existing keys.

Reordering entries in the map does not change resource identity because the keys remain the same.

The mental model is:

```text
count
→ position is identity

for_each
→ key is identity
```

## Deployment Workflow

Initialize the working directory:

```powershell
terraform init
```

Format and validate:

```powershell
terraform fmt
terraform validate
```

Review the plan:

```powershell
terraform plan
```

Before applying, predict the instance addresses and proposed resource actions.

Apply:

```powershell
terraform apply
```

Inspect state:

```powershell
terraform state list
```

For the final `for_each` version, the managed subnet addresses should be keyed by `web`, `app`, and `db`.

## Outputs

View outputs with:

```powershell
terraform output
```

The configuration exposes:

- the existing VNet name
- a map of subnet IDs keyed by the same keys used by `for_each`

This keeps the output identity aligned with the resource identity.

## Configuration, State, and Infrastructure

This lab also reinforces three separate concepts:

```text
configuration
≠
state
≠
actual Azure infrastructure
```

The existing Resource Group and VNet can exist in Azure without being managed by this lab's Terraform state.

The LAB-006 subnets become managed by this working directory when Terraform creates them and records their resource-instance bindings in state.

## Key Lesson

Both `count` and `for_each` can create multiple instances of one resource block, but they use different identity models.

Use the identity model that matches the data:

```text
ordered, positional instances
→ count

named, independently identified instances
→ for_each
```

For subnet names such as `web`, `app`, and `db`, keyed identity makes changes easier to reason about because the Terraform address communicates what each instance represents.

## Cleanup

When the LAB-006 subnets are no longer needed:

```powershell
terraform plan -destroy
terraform destroy
```

Review the destroy plan before confirming it. The existing Resource Group and VNet are data sources and are not intended to be destroyed by this configuration.

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
