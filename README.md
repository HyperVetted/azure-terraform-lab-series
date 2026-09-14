# Azure Terraform Labs

A hands-on Terraform repository focused on building practical **Infrastructure as Code** skills with **Microsoft Azure** while following a structured **HashiCorp Terraform Associate 004** learning path.

This repository is intended to demonstrate real Terraform usage through progressively more advanced labs. The emphasis is on understanding how Terraform behaves, not just memorizing syntax or certification facts.

---

## Project Goals

The goals of this repository are to:

- build practical Terraform skills through real Azure deployments
- improve HCL reading and writing ability
- understand Terraform plans before applying changes
- develop safe habits around state and infrastructure changes
- practice reusable and maintainable Terraform configuration
- prepare for the Terraform Associate 004 certification
- document hands-on Infrastructure as Code work in a public GitHub portfolio

---

## Technologies Used

- Terraform CLI
- HashiCorp Configuration Language (HCL)
- Microsoft Azure
- AzureRM Provider
- Azure CLI
- PowerShell
- Visual Studio Code
- Git
- GitHub

Azure is used as the hands-on platform, while Terraform concepts are kept provider-independent whenever possible.

---

## Repository Structure

Each lab is kept in its own directory so configurations stay isolated and easy to understand.

```text
azure-terraform-labs/
│
├── README.md
├── .gitignore
│
├── lab-001-*/
├── lab-002-*/
├── lab-003-*/
└── ...
```

A typical lab directory may contain:

```text
lab-example/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars.example
```

Not every lab uses every file. Terraform reads all `.tf` files in the current working directory as one configuration.

---

## Lab Roadmap

The repository follows a progressive lab series covering the major Terraform concepts needed for practical use and Terraform Associate 004 preparation.

| Lab | Focus |
|---|---|
| LAB-001 | First Azure Resource |
| LAB-002 | Provider Lifecycle |
| LAB-003 | Resource References and Dependencies |
| LAB-004 | Existing Infrastructure with Data Sources |
| LAB-005 | Parameterized Azure Network |
| LAB-005B | Structured Input Network |
| LAB-006 | `count` and `for_each` |
| LAB-007 | Plan Interpretation and Resource Lifecycle |
| LAB-008 | Validation and Conditions |
| LAB-009 | Local Modules |
| LAB-010 | Registry Modules |
| LAB-011 | Terraform State Inspection |
| LAB-012 | Remote State and Backends |
| LAB-013 | Drift and Refresh |
| LAB-014 | State Refactoring |
| LAB-015 | Importing Existing Infrastructure |
| LAB-016 | HCP Terraform Workflow |
| LAB-017 | Integrated Azure Capstone |

Labs are added to the repository as they are completed and cleaned up for public use.

---

## Topics Covered

### Terraform Fundamentals

- Terraform CLI workflow
- Terraform configuration files
- provider configuration
- resource blocks
- working directories
- formatting and validation

### Infrastructure as Code

- declarative infrastructure
- desired state
- repeatability
- idempotency
- infrastructure lifecycle
- version-controlled configuration

### Providers

- provider plugins
- provider source addresses
- `required_providers`
- provider configuration
- provider authentication
- provider version constraints
- `.terraform.lock.hcl`
- `.terraform/`
- `terraform init`
- `terraform init -upgrade`

### Resources and Dependencies

- resource addresses
- arguments
- attributes
- computed attributes
- resource references
- implicit dependencies
- explicit dependencies
- dependency graphs
- data sources

### Variables and Reusable Values

- input variables
- variable types
- defaults
- `.tfvars`
- `.auto.tfvars`
- environment variables
- CLI variable values
- locals
- outputs
- variable precedence

### HCL Data and Expressions

- strings
- numbers
- booleans
- lists
- sets
- maps
- objects
- tuples
- expressions
- functions
- collection access
- nested data structures

### Resource Generation

- `count`
- `count.index`
- `for_each`
- `each.key`
- `each.value`
- resource instance addressing

### Plan and Lifecycle Behavior

- create
- update
- destroy
- replacement
- lifecycle meta-arguments
- controlled configuration changes

### Validation and Security

- variable validation
- preconditions
- postconditions
- check blocks
- sensitive variables
- sensitive outputs
- state security
- secret-handling practices

### State and Infrastructure Management

- local state
- resource bindings
- state inspection
- remote backends
- drift
- refresh behavior
- state movement
- import
- troubleshooting

### Larger Terraform Workflows

- local modules
- Registry modules
- provider aliases
- CLI workspaces
- HCP Terraform
- integrated Azure infrastructure

---

## Core Workflow

A typical lab follows this Terraform workflow:

```text
WRITE CONFIGURATION
        ↓
terraform fmt
        ↓
terraform validate
        ↓
terraform plan
        ↓
REVIEW PROPOSED CHANGES
        ↓
terraform apply
        ↓
VERIFY INFRASTRUCTURE
        ↓
INSPECT STATE / OUTPUTS
        ↓
MODIFY AND REPEAT
```

Common commands include:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
terraform destroy
```

---

## Core Terraform Concepts

### Configuration

Terraform configuration describes the desired infrastructure.

```text
.tf files
→ what should exist
```

### State

Terraform state records the relationship between Terraform resource addresses and real infrastructure objects.

```text
configuration
≠
state
≠
actual infrastructure
```

These are related, but they are not interchangeable.

### Providers

Terraform Core uses providers to interact with external platforms.

For Azure:

```text
Terraform Core
      ↓
AzureRM Provider
      ↓
Azure APIs
      ↓
Azure Resources
```

### Resource vs Data Source

```text
resource
→ Terraform manages lifecycle

data source
→ Terraform reads existing infrastructure
```

### Argument vs Attribute

```text
argument
→ value supplied to a block

attribute
→ value read from a resource or data source
```

### Variable vs Local vs Output

```text
variable
→ external input

local
→ internal derived/reusable value

output
→ selected value exposed by Terraform
```

---

## Running a Lab

### 1. Clone the repository

```powershell
git clone <repository-url>
cd azure-terraform-labs
```

### 2. Enter a lab directory

```powershell
cd <lab-directory>
```

### 3. Authenticate to Azure

```powershell
az login
```

Verify the active Azure account if needed:

```powershell
az account show
```

### 4. Configure input values

If the lab includes:

```text
terraform.tfvars.example
```

copy it:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Then update the values for your own Azure environment.

### 5. Initialize Terraform

```powershell
terraform init
```

### 6. Format and validate

```powershell
terraform fmt
terraform validate
```

### 7. Review the plan

```powershell
terraform plan
```

Always review the proposed actions before applying.

### 8. Apply

```powershell
terraform apply
```

### 9. Inspect results

Depending on the lab:

```powershell
terraform output
terraform state list
```

### 10. Clean up

When appropriate:

```powershell
terraform destroy
```

Always review the destroy plan before confirming it.

---

## State Isolation Between Labs

Each lab should be treated as its own Terraform working directory.

Do not copy Terraform-generated state or working data between unrelated labs:

```text
terraform.tfstate
terraform.tfstate.backup
.terraform/
```

A resource that exists in Azure is not automatically part of a Terraform state.

Terraform manages infrastructure through the relationship between:

```text
configuration
state
actual infrastructure
```

Keeping labs isolated helps prevent accidental changes to resources created by another configuration.

---

## Git and Security

This repository is intended to be safe for public GitHub use.

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Do not commit:

- Azure credentials
- client secrets
- access tokens
- private keys
- passwords
- sensitive outputs
- secrets stored in variable files

Use:

```text
terraform.tfvars.example
```

to document expected inputs without publishing real environment-specific values.

A `.terraform.lock.hcl` file is generally safe and useful to commit because it records provider dependency selections for reproducible Terraform runs.

---

## Documentation Standard

Each completed lab should include a README that explains:

- what the lab builds
- what Terraform concepts it demonstrates
- prerequisites
- file structure
- important configuration decisions
- deployment steps
- verification steps
- expected behavior
- cleanup
- lessons learned

The goal is for each lab to be understandable without needing access to the original study notes.

---

## Learning Approach

This repository follows a practical learning model:

```text
UNDERSTAND
   ↓
READ
   ↓
WRITE
   ↓
RUN
   ↓
INSPECT
   ↓
CHANGE
   ↓
TROUBLESHOOT
   ↓
EXPLAIN
```

The emphasis is on being able to explain **why Terraform behaved the way it did**, not only whether a command succeeded.

---

## End Goal

The long-term goal is to be able to work confidently in an unfamiliar Terraform repository and:

- understand the configuration structure
- trace value sources
- identify resource dependencies
- make controlled changes
- interpret execution plans
- work safely with state
- troubleshoot errors
- understand provider behavior
- explain Terraform's decisions

The Terraform Associate certification is one milestone in that process; practical Terraform ability is the broader goal.
