# LAB-016 — Local Terraform vs HCP Terraform

Compare local Terraform CLI execution and state with CLI-driven remote execution in HCP Terraform. Both configurations use the built-in `terraform_data` resource, so no Azure provider, credentials, or billable infrastructure is required.

## Files

- `local/main.tf` — local execution and the default local state backend.
- `hcp/main.tf` — HCP `cloud` block, a workspace-supplied input variable, and remote execution.
- `.gitignore` — prevents local state, variable files, and other sensitive artifacts from being committed.

These are separate Terraform root configurations. Run Terraform from each folder independently.

## Prerequisites

- Terraform CLI 1.5 or newer.
- For the HCP configuration, an HCP Terraform organization, a CLI-driven workspace named `lab-016-remote-compare` with **Remote** execution enabled, and `terraform login` authentication.

## A. Local execution

1. Open a terminal in `local/`.
2. Run `terraform init`, `terraform fmt -check`, `terraform validate`, and `terraform plan`.
3. Review the plan, then run `terraform apply`.
4. Inspect `terraform state list` and confirm that `terraform.tfstate` exists in the local directory.
5. Run `terraform destroy` and confirm that `terraform state list` is empty.

With no `cloud` or alternative backend configured, plan/apply execute locally and state is stored by the default local backend.

## B. HCP remote execution

1. Create a CLI-driven HCP workspace named `lab-016-remote-compare` and set execution mode to **Remote**; keep auto-apply disabled.
2. Under HCP workspace Variables, add the **Terraform variable** `run_label` with value `hcp_compare` (not sensitive; HCL format disabled).
3. In `hcp/main.tf`, replace `YOUR_HCP_ORGANIZATION` with your own HCP organization name. Use your actual workspace name if different.
4. Open a terminal in `hcp/`. Run `terraform login` if needed, then `terraform init`, `terraform fmt -check`, and `terraform validate`.
5. Run `terraform plan` and inspect the HCP run URL and plan actions.
6. Run `terraform apply` after reviewing the plan.
7. Use `terraform state list` and the HCP workspace's States and Runs views to inspect the resource and remote state.
8. Run `terraform destroy`, verify the proposed destruction targets only `terraform_data.remote_probe`, and confirm that `terraform state list` is empty.

With Remote execution, the CLI sends the configuration and streams the output, while HCP Terraform executes the plan/apply and manages the workspace state. The input variable comes from the HCP workspace.

## Comparison

| Aspect | `local/` | `hcp/` |
|---|---|---|
| Command starts | Local terminal | Local terminal |
| Plan/apply executes | Local machine | HCP remote worker |
| State is stored | Local `terraform.tfstate` | HCP workspace |
| Example input | Literal string in HCL | HCP workspace variable |
| Azure credentials | Not required | Not required |

## Cleanup and security

Inspect every plan before applying or destroying. Neither example provisions Azure resources. HCP workspace history may remain after the managed resource is destroyed.

Never commit `.terraform/`, `terraform.tfstate*`, real `.tfvars`, plan files, tokens, credentials, or private run output. The example HCP organization name is intentionally a value you must replace.
