# Amaris Azure Terraform Challenge

This repository demonstrates **reusable, secure, and maintainable IaC** on Azure using **Terraform** and **GitHub Actions**.

> **Conventions (important):**
> - Naming: `prefix-env-region-resourcetype` (example: `amaris-dev-eastus-vnet`).
> - Environments: isolated **resource groups** per environment (subscriptions can be added later without code changes).
> - All comments are in **English**, intentionally **verbose and explanatory**.
> - Remote state: `azurerm` backend (Storage Account). **Fill in the placeholders** in each `envs/*/main.tf` backend block.
> - Auth in CI: **OIDC** with `azure/login@v2` and **GitHub Environment variables** (no client secrets).
> - Security: SSH keys only for Linux VM; public access limited to **dev**; **prod** has stricter defaults.

## Structure
```
modules/
  vnet/                 # Reusable VNET module
envs/
  dev/                  # Development (eastus): VM + Storage
  prod/                 # Production-like (westeurope): stricter NSG
.github/workflows/
  terraform.yml         # Validate/Plan/Apply using env-specific vars
  terraform-docs.yml    # Auto-generate module docs on PR/push
.pre-commit-config.yaml # fmt/validate + tflint + tfsec
tflint.hcl              # Linter config
```

## Quickstart (local)
1. Install: Terraform >= 1.6, Azure CLI, pre-commit, tflint, tfsec.
2. Create an Azure **resource group + storage account + container** for remote state.
3. In `envs/dev/main.tf` and `envs/prod/main.tf`, fill the backend block placeholders:
   - `resource_group_name`, `storage_account_name`, `container_name`.
4. Login to Azure and run:
   ```bash
   cd envs/dev
   terraform init -backend-config="key=dev.tfstate"
   terraform plan -out=plan.tfplan
   terraform show -no-color plan.tfplan > plan.txt   # Share this plan output
   terraform apply
   ```

## GitHub Environments & Variables (per environment login)
We use **GitHub Environment variables** so each environment (dev/prod) can have its own Azure login coordinates.
Create two environments in your repo settings: **dev** and **prod**.

For each environment, add these **Variables** (Settings → Environments → <env> → Variables):
- `AZURE_CLIENT_ID` – App registration client ID used for OIDC login.
- `AZURE_TENANT_ID` – Azure AD tenant (directory) ID.
- `AZURE_SUBSCRIPTION_ID` – Target subscription ID for that environment.

> These are identifiers (not secrets). No client secret is required thanks to **OIDC**.
> The workflow references them via `${{ vars.AZURE_* }}` and sets `environment: dev|prod` per job.

## CI Setup (OIDC)
1. Create an **Azure AD app registration** and grant it **Contributor** on the target scope (subscription or RGs).
2. Add a **Federated Credential** for your GitHub repo & workflow.
3. Create GitHub **Environments**: `dev` and `prod`. Add the three variables above. For `prod`, require a reviewer.

## Policies and Tagging
- Required tags: `env`, `owner`, `cost`, `region`. Enforced by a variable `validation` in the module.

## Auto generated Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.112 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.112 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vnet"></a> [vnet](#module\_vnet) | ./modules/vnet | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.app_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_storage_account.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.artifacts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | n/a | `list(string)` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->


## Tests (bonus)
- A Terratest scaffold is included under `tests/` (optional).
