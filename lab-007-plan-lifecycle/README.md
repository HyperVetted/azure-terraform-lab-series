# LAB-007 — Plan Interpretation and Resource Lifecycle

This lab is about learning to **predict what Terraform will do before running `terraform plan`**.

The goal is not to memorize symbols. The goal is to look at a change and reason through:

```text
What does configuration want?
What does Terraform already know in state?
What exists in Azure?
Can the provider change the existing resource in place?
```

That reasoning leads to the plan action.

## What This Lab Builds

```text
Existing Azure Resource Group
        │
        └── LAB-007 Virtual Network: 10.77.0.0/16
                │
                ├── lab007-web-snet  10.77.1.0/24
                └── lab007-app-snet  10.77.2.0/24
```

The Resource Group already exists and is read with a data source.

Terraform manages only the LAB-007 VNet and subnets.

## What You Should Learn

By the end of the lab, you should be able to explain these four actions without guessing:

| Action | Meaning |
|---|---|
| `+` | Terraform needs to create something |
| `~` | Terraform can change the existing resource in place |
| `-` | Terraform manages something that configuration no longer wants |
| replacement | Terraform still wants the resource, but the current instance cannot be changed into the requested form in place |

You also practice four lifecycle settings:

- `prevent_destroy`
- `ignore_changes`
- `create_before_destroy`
- `replace_triggered_by`

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

The committed `.tf` files show the clean baseline configuration after the experiments were reverted.

## Before Starting

You need:

- Terraform CLI
- Azure CLI authentication
- an existing Azure Resource Group
- Contributor permission inside that Resource Group

Copy the example variable file to `terraform.tfvars` and enter the Resource Group name used for the lab.

## The Mental Model for This Lab

Keep these three things separate:

```text
CONFIGURATION
What the HCL says should exist

STATE
What Terraform is currently tracking

AZURE
What actually exists in the cloud
```

They are related, but they are not the same thing.

A plan is Terraform working out what needs to change so the managed Azure resources match configuration.

## Step 1 — Build the Baseline

Initialize the working directory:

```powershell
terraform init
```

Format and validate:

```powershell
terraform fmt
terraform validate
```

Before the first plan, stop and predict.

### Ask yourself

- Does the VNet already exist in this lab's state?
- Do either of the subnets exist in this lab's state?
- Is the Resource Group a resource or a data source?

Then run:

```powershell
terraform plan
```

The important part is not just seeing `+` symbols. Explain **why** they appear.

The VNet and subnets are declared as managed resources but are not yet recorded in this lab's state, so Terraform proposes creating them.

The existing Resource Group is different. Terraform only reads it through a data source, so Terraform does not propose creating it.

Apply the baseline:

```powershell
terraform apply
```

Then run another plan.

```powershell
terraform plan
```

A clean `No changes` result means the baseline is synchronized:

```text
configuration wants the resources
state tracks the resources
Azure contains the resources
```

That clean baseline is where every experiment begins and ends.

---

# Plan Experiments

For every experiment, use the same process:

```text
1. Make ONE change
2. Predict the plan
3. Run terraform plan
4. Find the action symbol
5. Explain why Terraform chose it
6. Revert the change
7. Confirm No changes again
```

Keeping one change at a time makes the plan easier to understand.

## Experiment 1 — Update in Place

Change one VNet tag value.

### Before running plan

Ask:

> Does changing a tag require Terraform to throw away the whole VNet?

Then run `terraform plan`.

The expected idea is an **update in place**.

Why?

The VNet already exists, Terraform still wants that same VNet, and AzureRM can change its tags without replacing the entire resource.

Mental model:

```text
resource exists
+
configuration changed
+
provider can modify existing object
=
~ update in place
```

Revert the tag and return to `No changes`.

## Experiment 2 — Replacement

Change the web subnet name.

### Before running plan

Ask:

> Is Terraform removing the subnet because I no longer want one, or does it still want a subnet with a different identity?

Terraform still wants the resource, but this change requires a new Azure subnet instance.

That is **replacement**, not a simple destroy.

Mental model:

```text
resource is still declared
+
existing instance cannot become the requested form in place
=
replace old instance with a new one
```

This is an important distinction:

```text
destroy
→ configuration no longer wants the resource

replacement
→ configuration still wants the resource, but not the current instance
```

Restore the original name and return to a clean plan.

## Experiment 3 — Create

Add a third subnet to configuration.

### Before running plan

Ask:

> Does Terraform already have a managed instance for this new resource?

It does not.

Configuration now asks for something that does not exist in this lab's state, so Terraform proposes `+ create`.

Mental model:

```text
configuration: yes
state: no managed instance
=
+ create
```

Remove the temporary subnet and return to the baseline.

## Experiment 4 — Destroy

Temporarily remove the app subnet resource block from configuration.

The subnet still exists in Azure and Terraform still has it recorded in state.

### Before running plan

Ask:

> What happens when Terraform manages an object, but configuration stops declaring it?

Terraform interprets that as:

```text
configuration: no longer wanted
state: still managed
Azure: still exists
=
- destroy
```

This is why removing a resource block is not the same as telling Terraform to forget it.

Restore the resource block and return to `No changes`.

## Experiment 5 — Let the Provider Answer

Change the VNet address space.

Do not assume the answer first.

This experiment reinforces an important rule:

> Terraform decides what changed, but the provider schema helps determine whether that change can happen in place or requires replacement.

Make your prediction, run the plan, and inspect what AzureRM proposes.

The skill here is not memorizing every AzureRM argument. It is learning to read the plan when provider behavior matters.

Restore the original address space afterward.

---

# Lifecycle Experiments

Lifecycle settings change how Terraform handles certain resource changes.

They do not replace the normal configuration/state model. They modify specific parts of Terraform's normal behavior.

## Experiment 6 — `prevent_destroy`

Add `prevent_destroy` to the web subnet, then make a change that would normally require replacement.

Replacement includes destruction of the old instance.

### Ask yourself

> If Terraform must destroy the old subnet to complete this replacement, what should `prevent_destroy` do?

Terraform blocks the destructive operation.

Mental model:

```text
normal plan needs destruction
+
prevent_destroy = true
=
Terraform refuses the destructive plan
```

This setting is a guardrail. It is useful for resources where accidental destruction would be costly.

Restore the baseline when finished.

## Experiment 7 — `ignore_changes`

Configure the VNet to ignore changes to tags, then change a tag value.

Normally Terraform notices the difference and tries to reconcile it.

With tags ignored, Terraform is being told:

> Do not manage differences for this selected argument after the resource exists.

Mental model:

```text
tag differs
+
tags are ignored
=
that tag difference does not create a plan action
```

Important: this does **not** mean Terraform ignores every other difference on the resource.

If another managed argument changes, Terraform can still take action because of that other difference.

Restore the tag and lifecycle setting afterward.

## Experiment 8 — `create_before_destroy`

Configure the web subnet to create its replacement before destroying the old instance, then make a replacement-triggering change.

Without this lifecycle setting, replacement normally means the old instance can be destroyed before the new one is created.

`create_before_destroy` changes the ordering.

Mental model:

```text
replacement is already required
+
create_before_destroy
=
try to create replacement first
then remove old instance
```

It does **not** cause replacement by itself.

It only changes the order when replacement is already necessary.

Restore the baseline afterward.

## Experiment 9 — `replace_triggered_by`

Configure the app subnet so a managed change to the VNet can trigger replacement of the app subnet.

This experiment separates two roles:

```text
VNet
→ watched resource that changes

app subnet
→ resource containing replace_triggered_by
→ resource that gets replaced
```

The important question is:

> Which object changed, and which object is configured to react to that change?

`replace_triggered_by` lets a change to one managed Terraform object become a reason to replace another managed object.

Remove the temporary lifecycle setting when finished and return to a clean plan.

---

# Destroy and Redeploy Test

At the end of the lab, the LAB-007 resources were destroyed.

```powershell
terraform destroy
```

This is where configuration, state, and Azure become especially useful to separate.

Immediately after destroy:

### Configuration

The `.tf` code still exists.

Terraform still has declarations saying the VNet and subnets **should exist** when the configuration is applied.

### State

The destroyed VNet and subnet managed instances are no longer tracked as existing managed resources.

### Azure

The LAB-007 VNet and subnets are gone.

The existing Resource Group remains because this lab only reads it as a data source.

So the situation is now:

```text
configuration says: VNet and subnets should exist
state says: those managed instances do not currently exist
Azure says: those lab resources do not exist
```

Running Terraform again therefore produces creation actions.

The lab was then redeployed successfully.

That proves an important Terraform idea:

> `terraform destroy` removes managed infrastructure. It does not erase the Terraform configuration that describes that infrastructure.

## Final Lesson

When reading a plan, do not start by memorizing the symbol.

Start with these questions:

```text
1. Is the resource still in configuration?
2. Is Terraform already tracking an instance in state?
3. Does the real Azure object exist?
4. What changed?
5. Can the provider change the existing object in place?
6. Is lifecycle configuration changing the normal behavior?
```

Then the plan symbols make much more sense.

## Cleanup

Before destroying lab resources, review the plan:

```powershell
terraform plan -destroy
terraform destroy
```

Only the VNet and subnets are managed by this lab. The existing Resource Group should remain.

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
