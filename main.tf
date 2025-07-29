#############################################
# Terraform + Provider configuration
#############################################

terraform {
  # Pin a sensible floor for Terraform. If you rely on specific features,
  # keep this aligned with your toolchain/CI image.
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Keep provider on a stable minor track. Bump intentionally in PRs.
      version = "~> 3.112"
    }
  }
}

# AzureRM provider enables ARM APIs for all azurerm_* resources below.
# The 'features {}' block is required even when empty.
provider "azurerm" {
  features {}
}

#############################################
# Resource Group: environment isolation
#############################################

# One Resource Group per environment keeps lifecycle boundaries clean.
# If you later move to separate subscriptions, the code stays the same.
resource "azurerm_resource_group" "rg" {
  # Naming convention: prefix-env-region-type (uniform and grep-friendly).
  name     = "${var.prefix}-${var.env}-${var.region}-rg"
  location = var.region
  # Governance: consistent tagging for cost/ownership/filters.
  tags     = var.tags
}

#############################################
# Networking: reusable VNet module
#############################################

# Encapsulates VNet, subnets, optional NSGs, etc.
# Inputs are passed through from root variables to keep this root thin.
module "vnet" {
  # Module path is local; publishable modules would use a git or registry source.
  source              = "./modules/vnet"

  # VNet name follows the shared convention for easy discovery.
  name                = "${var.prefix}-${var.env}-${var.region}-vnet"

  # Place all network resources into the environment RG in this example.
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region

  # Addressing and subnets come from variables to avoid hard-coding.
  address_space       = var.address_space
  subnets             = var.subnets

  # Tags propagate from root for consistent governance.
  tags                = var.tags
}

#############################################
# NIC for the application VM (no public IP here)
#############################################

# A single NIC in the 'app' subnet. If you later add an ILB or PIP, this block
# is the handoff point (add secondary IP configs, attach PIP, etc.).
resource "azurerm_network_interface" "app_nic" {
  name                = "${var.prefix}-${var.env}-${var.region}-app-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region

  ip_configuration {
    name                          = "primary"
    # Subnet IDs are exposed by the VNet module outputs.
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

#############################################
# Compute: lightweight Linux VM (dev-only)
#############################################

# Create the VM only in dev to keep prod minimal and cheaper.
# This pattern is simple and explicit; for larger stacks prefer count at a
# higher level or separate stacks per env.
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.env == "dev" ? 1 : 0

  name                  = "${var.prefix}-${var.env}-${var.region}-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.region

  # Size chosen to be free-tier/friendly for a demo; 
  size                  = "Standard_B1ms"

  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  # SSH-only; password auth is disabled for better baseline security.
  # NOTE: This path is relative to the working directory where 'terraform apply' runs.
  # Consider promoting this into a variable (e.g., var.ssh_public_key_path) to avoid path issues in CI.
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(".ssh/id_rsa-${var.env}.pub")
  }

  disable_password_authentication = true

  # OS disk kept standard/LRS to control costs; use Premium_LRS for IO-critical workloads.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Canonical Ubuntu LTS (Jammy). Using 'latest' eases patching but pins you
  # to a major/LTS line. For strict reproducibility, pin an exact version.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

#############################################
# Storage: general-purpose account + private container
#############################################

# Storage account for artifacts, logs, or Terraform remote state in other cases.
# Name must be globally unique, 3–24 lowercase alphanumerics; we strip dashes above.
resource "azurerm_storage_account" "sa" {
  name                     = replace("${var.prefix}${var.env}${var.region}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.region

  # Standard_LRS is cost-effective for dev; adjust tier/replication by RPO/RTO needs.
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enforce modern TLS; public blob access remains disabled by default in AzAPI,
  # but be explicit when you need to harden.
  min_tls_version          = "TLS1_2"

  tags                     = var.tags
}

# Private container for build artifacts or application payloads.
# Access stays private; use SAS or role assignments for access management.
resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
