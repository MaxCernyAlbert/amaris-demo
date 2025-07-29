terraform {
  backend "azurerm" {
    resource_group_name  = "rg-operation"
    storage_account_name = "stamaristerraformdev"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
    use_oidc             = true
  }
}
