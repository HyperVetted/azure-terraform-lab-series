# LAB-005B — Structured Input Azure Network

This lab extends **LAB-005 — Parameterized Azure Virtual Network** by changing how subnet CIDR data is represented and consumed.

The Azure architecture remains intentionally simple: one virtual network and three explicit subnet resources. The learning objective is not dynamic resource generation. It is to reason about **structured Terraform values, collection access, and expression result types**.

## What the Lab Builds

- 1 Azure Virtual Network
- 3 Azure subnets: web, app, and management
- Common tags on the VNet
- Terraform outputs for the VNet, subnet IDs, and existing Resource Group location

The Resource Group already exists. Terraform reads it with an AzureRM data source rather than creating or managing it.

## Architecture

```text
Existing Azure Resource Group
        │
        │ read with a data source
        ▼
lab005b-lab-vnet
10.80.0.0/16
        │
        ├── lab005b-lab-web-snet
        │   10.80.1.0/24
        │
        ├── lab005b-lab-app-snet
        │   10.80.2.0/24
        │
        └── lab005b-lab-mgmt-snet
            10.80.3.0/24
```

## Why LAB-005B Exists

LAB-005 used three separate subnet CIDR variables:

```text
web_cidr
app_cidr
mgmt_cidr
```

LAB-005B replaces those isolated inputs with one structured variable:

```hcl
variable "subnet_cidr" {
  type = list(list(string))
}
```

The subnet resources access the nested values positionally:

```hcl
var.subnet_cidr[0]
var.subnet_cidr[1]
var.subnet_cidr[2]
```

The convention used in this lab is:

```text
[0] → web
[1] → app
[2] → mgmt
```

This is intentionally still implemented with three explicit `azurerm_subnet` resource blocks. `count` and `for_each` are reserved for the next phase of the lab series.

## Concepts Practiced

- nested collection types
- `list(list(string))`
- list indexing
- expression result types
- provider argument type requirements
- variables and `terraform.tfvars`
- locals
- outputs
- data sources
- resource references
- implicit dependencies
- Terraform state isolation
- plan/apply workflow
- idempotency
- troubleshooting `terraform validate`

This lab intentionally does **not** use:

- `count`
- `for_each`
- modules
- a remote backend

## Repository Structure

```text
lab-005b-structured-input-network/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── paramvnetlab.tf
├── outputs.tf
└── terraform.tfvars.example
```

| File | Purpose |
|---|---|
| `providers.tf` | Declares and configures the AzureRM provider |
| `variables.tf` | Defines the input types, including the nested subnet collection |
| `locals.tf` | Builds resource names and common tags |
| `paramvnetlab.tf` | Reads the existing Resource Group and creates the VNet/subnets |
| `outputs.tf` | Exposes useful resource attributes |
| `terraform.tfvars.example` | Public-safe example input values |
| `README.md` | Documents the lab and its behavior |

Terraform reads all `.tf` files in the working directory as one configuration. The filename `paramvnetlab.tf` has no special Terraform behavior and could also be named `main.tf`.

## Prerequisites

- Terraform CLI
- Azure CLI
- access to an Azure subscription
- an existing Azure Resource Group
- Azure authentication

Authenticate:

```powershell
az login
```

Verify Terraform:

```powershell
terraform version
```

## Configure the Lab

Copy the example variable file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Update the Resource Group name:

```hcl
rg_name = "your-existing-resource-group"
```

The included example data is:

```hcl
project = "lab005b"

vnet_address_space = ["10.80.0.0/16"]

subnet_cidr = [
  ["10.80.1.0/24"],
  ["10.80.2.0/24"],
  ["10.80.3.0/24"]
]
```

`environment` is not supplied in the example file because `variables.tf` provides the default:

```hcl
default = "lab"
```

That produces names such as:

```text
lab005b-lab-vnet
lab005b-lab-web-snet
lab005b-lab-app-snet
lab005b-lab-mgmt-snet
```

## The Type-Reasoning Lesson

The highest-value troubleshooting point in this lab came from `terraform validate`.

An earlier version used:

```hcl
type = list(string)
```

With that type:

```text
var.subnet_cidr
→ list(string)

var.subnet_cidr[0]
→ string
```

However, AzureRM's subnet `address_prefixes` argument requires:

```text
list(string)
```

So this was invalid:

```text
string
≠
list(string)
```

The final structure changed the variable to:

```hcl
list(list(string))
```

Now Terraform evaluates:

```text
var.subnet_cidr
→ list(list(string))

var.subnet_cidr[0]
→ list(string)

address_prefixes
→ list(string)
```

The expression result type therefore matches the provider argument type.

The general reasoning pattern is:

```text
whole value type
        ↓
access expression
        ↓
resulting value type
        ↓
required consumer/provider type
```

## Collection Access Model

```text
OBJECT → .property
MAP    → ["key"]
LIST   → [index]
```

The important question is not only *how* to access the collection, but also:

> What type does that access expression return?

## Deployment

Initialize:

```powershell
terraform init
```

Format:

```powershell
terraform fmt
```

Validate:

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

Review the plan:

```powershell
terraform plan
```

For a clean first deployment, the completed lab produced:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

The four managed resources are:

```text
azurerm_virtual_network.main
azurerm_subnet.web
azurerm_subnet.app
azurerm_subnet.mgmt
```

The existing Resource Group is a data source, so it is not counted as a resource being created.

Apply:

```powershell
terraform apply
```

The completed lab produced:

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

## Outputs

View the outputs:

```powershell
terraform output
```

The configuration exposes:

```text
vnet_name
vnet_id
web_snet_id
app_snet_id
mgmt_snet_id
existing_rg_location
```

## Inspect Terraform State

```powershell
terraform state list
```

Expected addresses:

```text
data.azurerm_resource_group.existing
azurerm_subnet.app
azurerm_subnet.mgmt
azurerm_subnet.web
azurerm_virtual_network.main
```

A resource existing in Azure does not automatically mean that a particular Terraform state manages it.

```text
configuration
≠
state
≠
actual infrastructure
```

Each lab should use its own Terraform working directory and state.

Do not copy these from another lab:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
```

## Verify Idempotency

After deployment, with no configuration or infrastructure changes:

```powershell
terraform plan
```

The completed lab returned:

```text
No changes. Your infrastructure matches the configuration.
```

That confirms Terraform's configuration, state, and refreshed Azure infrastructure agree.

## LAB-005 vs LAB-005B

| Area | LAB-005 | LAB-005B |
|---|---|---|
| Main learning goal | Parameterization | Structured values and type reasoning |
| VNet | 1 explicit resource | 1 explicit resource |
| Subnets | 3 explicit resources | 3 explicit resources |
| Subnet inputs | 3 separate variables | 1 nested collection |
| CIDR access | direct variable references | list indexes |
| `count` / `for_each` | not used | not used |
| Azure topology | VNet + 3 subnets | VNet + 3 subnets |

The infrastructure shape changed very little. The Terraform **data model** changed substantially.

## Design Note

`list(list(string))` is valid for this lab, but the meaning of `[0]`, `[1]`, and `[2]` depends on positional convention.

A keyed structure can be more self-documenting in larger configurations. That refactor is not required here because the purpose of this lab was to practice structured values and expression types without introducing dynamic resource instances.

## Cleanup

When the lab is no longer needed:

```powershell
terraform destroy
```

Review the destroy plan before confirming it.

The existing Resource Group is read through a data source and is not intended to be destroyed by this configuration.

## Security

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Do not publish credentials, secrets, tokens, or other sensitive values.

Commit `terraform.tfvars.example` instead of your real `terraform.tfvars`.
