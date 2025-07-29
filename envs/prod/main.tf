terraform {
  required_version = ">= 1.6"
  required_providers { azurerm = { source = "hashicorp/azurerm", version = "~> 3.112" } }
  backend "azurerm" {
    resource_group_name  = "rg-operation"
    storage_account_name = "stamaristerraformprod"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_oidc             = true

  }
}
provider "azurerm" {
  features {}
}

locals {
  prefix = "amaris"
  env    = "prod"
  region = "westeurope"
  tags   = { env = local.env, owner = "platform", cost = "prod", region = local.region }
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-${local.env}-${local.region}-rg"
  location = local.region
  tags     = local.tags
}

module "vnet" {
  source              = "../../modules/vnet"
  name                = "${local.prefix}-${local.env}-${local.region}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region
  address_space       = ["10.20.0.0/16"]
  subnets = {
    app  = { address_prefixes = ["10.20.1.0/24"], service_endpoints = ["Microsoft.Storage"], nsg_rules = [] }
    data = { address_prefixes = ["10.20.2.0/24"], nsg_rules = [] }
  }
  tags = local.tags
}

resource "azurerm_network_interface" "app_nic" {
  name                = "${local.prefix}-${local.env}-${local.region}-app-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region
  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.prefix}${local.env}${local.region}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
