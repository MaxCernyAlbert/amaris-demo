
terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.112"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.env}-${var.region}-rg"
  location = var.region
  tags     = var.tags
}

module "vnet" {
  source              = "./modules/vnet"
  name                = "${var.prefix}-${var.env}-${var.region}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = var.tags
}

resource "azurerm_network_interface" "app_nic" {
  name                = "${var.prefix}-${var.env}-${var.region}-app-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.env == "dev" ? 1 : 0
  name                  = "${var.prefix}-${var.env}-${var.region}-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.region
  size                  = "Standard_B1ms"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.app_nic.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(".ssh/id_rsa-${var.env}.pub")
  }
  disable_password_authentication = true
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = var.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = replace("${var.prefix}${var.env}${var.region}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
