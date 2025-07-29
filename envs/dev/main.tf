terraform {
  required_version = ">= 1.6"
  required_providers { azurerm = { source = "hashicorp/azurerm", version = "~> 3.112" } }
  backend "azurerm" {
    resource_group_name  = "REPLACE_WITH_TFSTATE_RG"
    storage_account_name = "REPLACEWITHTFSTATEACCOUNT"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}
provider "azurerm" { features {} }

locals {
  prefix = "amaris"
  env    = "dev"
  region = "eastus"
  tags = {
    env    = local.env
    owner  = "platform"
    cost   = "dev"
    region = local.region
  }
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
  address_space       = ["10.10.0.0/16"]
  subnets = {
    app = {
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
      nsg_rules = [{
        name="allow_ssh"; priority=100; direction="Inbound"; access="Allow"; protocol="Tcp";
        source_port_range="*"; destination_port_range="22";
        source_address_prefix="*"; destination_address_prefix="*";
      }]
    }
    data = { address_prefixes = ["10.10.2.0/24"] }
  }
  tags = local.tags
}

resource "azurerm_public_ip" "vm_pip" {
  name                = "${local.prefix}-${local.env}-${local.region}-vm-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region
  allocation_method   = "Static"
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${local.prefix}-${local.env}-${local.region}-vm-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region
  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.prefix}-${local.env}-${local.region}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region
  size                = "Standard_B1ms"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  admin_ssh_key { username = "azureuser"; public_key = file("~/.ssh/id_rsa.pub") }
  disable_password_authentication = true
  os_disk { caching = "ReadWrite"; storage_account_type = "Standard_LRS" }
  source_image_reference { publisher = "Canonical"; offer = "0001-com-ubuntu-server-jammy"; sku = "22_04-lts-gen2"; version = "latest" }
  tags = local.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.prefix}${local.env}${local.region}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  tags                     = local.tags
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
