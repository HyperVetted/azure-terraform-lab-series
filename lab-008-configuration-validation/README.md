# LAB-008 — Configuration Validation

This lab focuses on **Terraform validation and custom conditions**.

The goal is to stop treating conditions as isolated syntax and instead decide:

```text
What am I protecting?
When should Terraform test it?
Should failure block the operation or report an assertion?
```

The lab uses Azure for hands-on practice, but the Terraform concepts are provider-independent.

## What This Lab Builds

```text
Existing Azure Resource Group
        │
        └── LAB-008 Virtual Network
                │
                ├── web-snet
                └── app-snet
```

The Resource Group already exists and is read through a data source.

Terraform manages only the LAB-008 VNet and subnets in this lab's local state.

## What You Should Learn

By the end of the lab, you should be able to choose and explain:

| Mechanism | Purpose |
|---|---|
| variable `validation` | decide whether caller-supplied input is allowed |
| `precondition` | require an assumption to be true before a resource operation proceeds |
| `postcondition` | assert something about the resulting resource after evaluation |
| `check` | evaluate an ongoing assertion without using it as a hard resource guard |
| `error_message` | describe the actual failed rule clearly |

The lab also reinforces:

- `for_each` with a map of subnet objects
- object attribute references with `each.value`
- provider type shape such as `string -> [string] -> list(string)`
- data-source vs managed-resource ownership
- destroy/redeploy reasoning

## Repository Structure

```text
lab-008-configuration-validation/
├── README.md
├── providers.tf
├── variables.tf
├── main.tf
└── terraform.tfvars.example
```

The public repository intentionally excludes real tfvars, Terraform state, saved plan files, and environment-specific values.

## Before Starting

You need:

- Terraform CLI 1.5+
- AzureRM provider 4.x
- Azure CLI authentication
- an existing Azure Resource Group
- Contributor permission inside that Resource Group

Copy the example variable file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Then replace the example Resource Group name with the real existing Resource Group used for the lab.

The public version uses a generic Resource Group prefix check. Adapt that precondition to the naming rule used in your environment.

## Baseline Configuration

Before adding failure experiments, establish a valid baseline.

Initialize, format, and validate:

```powershell
terraform init
terraform fmt
terraform validate
```

Before running the first plan, identify which objects are managed resources and which object is only being read.

The Resource Group is a data source:

```text
data.azurerm_resource_group.main
```

The VNet and subnets are managed resources.

Run:

```powershell
terraform plan
```

Then apply the baseline:

```powershell
terraform apply
```

Run another plan and confirm the configuration is synchronized:

```powershell
terraform plan
```

A clean baseline makes each validation experiment easier to reason about.

---

# Variable Validation

## Environment Validation

`var.environment` accepts only:

```text
dev
staging
prod
```

This is caller-input validation.

Mental model:

```text
caller supplies a value
        ↓
validation asks whether that value is allowed
        ↓
true  -> continue
false -> stop with the custom error message
```

To test it, temporarily set an invalid environment value and run Terraform.

The important question is:

> Does Terraform reject the input before normal resource planning can proceed?

Restore a valid value afterward.

## Location Validation

`var.location` is restricted to the approved Azure regions defined in the variable block.

This reinforces the difference between:

```text
type
-> what kind of value is this?

validation
-> is this particular value allowed?
```

Supply a disallowed region, inspect the custom validation error, then restore a valid value.

---

# Preconditions

A precondition protects an assumption that must hold before Terraform proceeds with the enclosing resource operation.

This lab uses preconditions for resource assumptions such as:

- the existing Resource Group following the expected naming rule
- the VNet being in the required Azure region before subnet operations proceed

Mental model:

```text
before Terraform proceeds
        ↓
is the required assumption true?
        ↓
true  -> continue
false -> stop with the precondition error
```

The important skill is reference precision.

For example:

```text
data.azurerm_resource_group.main
```

is the whole data-source object, while:

```text
data.azurerm_resource_group.main.name
```

is the string name attribute.

A valid HCL expression can still be wrong if it selects the wrong object or attribute.

---

# Postconditions

The subnet resource uses a postcondition to verify a property of the resulting subnet instance.

The key reference is:

```text
self
```

Inside a postcondition, `self` refers to the current resource instance being checked.

Mental model:

```text
Terraform evaluates the resource result
        ↓
postcondition checks a resulting property
        ↓
true  -> result is acceptable
false -> report the postcondition failure
```

Because the subnet resource uses `for_each`, `self` is especially useful: the condition checks the current subnet instance rather than trying to reference the full collection of resource instances.

---

# Check Blocks

The lab contains a top-level `check` block asserting that exactly two subnet definitions exist.

Mental model:

```text
configuration / infrastructure assumption
        ↓
check evaluates assertion
        ↓
true  -> assertion passes
false -> Terraform reports the failed check
```

This is useful for ongoing assertions that should be visible without modeling them as a hard input or resource guard.

The lab deliberately tests the difference between a failed check and a blocking validation or precondition.

---

# Error Messages

A custom condition is much more useful when its error describes the actual rule.

Prefer:

```text
vnet location must be eastus2
```

instead of:

```text
condition failed
```

A good error message answers:

```text
What rule was violated?
What value or behavior is required?
```

This makes debugging faster and keeps the Terraform configuration self-documenting.

---

# Provider Type Shape

Subnet CIDR input is stored as a string inside each subnet object.

AzureRM's subnet `address_prefixes` argument expects a list of strings.

So the value crosses a provider boundary like this:

```text
string
  ↓
[string]
  ↓
list(string)
```

This lab therefore reinforces a recurring Terraform skill:

> Correct reference does not automatically mean correct type shape.

Both the value and the shape expected by the provider matter.

---

# Destroy and Redeploy Test

After the validation exercises, destroy the LAB-008 managed infrastructure:

```powershell
terraform plan -destroy
terraform destroy
```

The existing Resource Group should remain because the lab only reads it through a data source.

Immediately after destroy:

```text
CONFIGURATION
still declares the VNet and subnets

STATE
no longer tracks those destroyed managed instances

AZURE
the LAB-008 VNet and subnets are gone
```

The `.tf` configuration still says those managed resources should exist.

Running Terraform again therefore proposes recreating them.

Redeploy:

```powershell
terraform plan
terraform apply
```

Then verify the final state:

```powershell
terraform plan
```

A final `No changes` result demonstrates that the configuration can recreate the lab after destruction and return to the desired state.

## Final Mental Model

When deciding which condition mechanism to use, ask:

```text
Is this caller input?
-> variable validation

Is this an assumption required before the resource proceeds?
-> precondition

Is this a property of the resulting resource?
-> postcondition

Is this an ongoing assertion I want Terraform to report?
-> check block
```

Then make the condition itself precise:

```text
1. What exact value am I testing?
2. Is the reference pointing to the object or property I intend?
3. Does the expression evaluate to bool?
4. Does the provider expect a different type shape at the boundary?
5. Does the error message describe the actual rule?
```

## Cleanup

When finished:

```powershell
terraform plan -destroy
terraform destroy
```

Only resources managed by this lab should be destroyed. The existing Resource Group remains outside LAB-008 ownership.

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
