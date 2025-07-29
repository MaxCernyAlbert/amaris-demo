variable "name" {
  type        = string
  description = "VNET name following naming convention, e.g., amaris-dev-eastus-vnet."
}
variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group where the VNET will be created."
}
variable "location" {
  type        = string
  description = "Azure region (e.g., eastus)."
}
variable "address_space" {
  type        = list(string)
  description = "List of CIDR blocks for the VNET address space."
}

variable "subnets" {
  description = <<EOT
Map of subnet definitions keyed by subnet logical name.
Each subnet can optionally define service endpoints, delegations, and inline NSG rules.
Example:
{
  app = {
    address_prefixes  = ["10.10.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
    delegations = [{
      name = "delegation1"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }]
    nsg_rules = [{
      name                       = "allow_ssh"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }]
  }
}
EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string # Inbound or Outbound
      access                     = string # Allow or Deny
      protocol                   = string # Tcp | Udp | *
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
}

variable "enable_ddos" {
  type        = bool
  default     = false
  description = "If true, associates the VNET with an existing DDoS Standard plan (must supply ddos_plan_id)."
}
variable "ddos_plan_id" {
  type        = string
  default     = null
  description = "Resource ID of an existing DDoS Standard plan. Used only when enable_ddos = true."
}
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources created by this module."

  validation {
    condition = (
      contains(keys(var.tags), "env") &&
      contains(keys(var.tags), "owner") &&
      contains(keys(var.tags), "cost") &&
      contains(keys(var.tags), "region")
    )
    error_message = "tags must include keys: env, owner, cost, region."
  }
}
