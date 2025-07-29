terraform {
  backend "azurerm" {
    resource_group_name  = "rg-operation"
    storage_account_name = "stamaristerraformprod"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_oidc             = true
  }
}
