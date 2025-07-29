terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.112" }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos && var.ddos_plan_id != null ? [1] : []
    content {
      id     = var.ddos_plan_id
      enable = var.enable_ddos
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = "${var.name}-${each.key}-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = try(each.value.service_endpoints, null)

  dynamic "delegation" {
    for_each = try(each.value.delegations, [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

}



resource "azurerm_network_security_group" "this" {
  for_each            = { for k, v in var.subnets : k => v.nsg_rules if length(try(v.nsg_rules, [])) > 0 }
  name                = "${var.name}-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
locals {
  flattened_nsg_rules = flatten([
    for subnet_key, subnet in var.subnets : [
      for r in try(subnet.nsg_rules, []) : merge(r, {
        subnet_key = subnet_key
        _key       = "${subnet_key}-${r.name}"
      })
    ]
  ])
}


resource "azurerm_network_security_rule" "this" {
  for_each = { for r in local.flattened_nsg_rules : r._key => r }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, null)
  destination_port_range      = try(each.value.destination_port_range, null)
  source_address_prefix       = try(each.value.source_address_prefix, null)
  destination_address_prefix  = try(each.value.destination_address_prefix, null)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name

  # Optionally handle lists for port/address prefixes
  source_port_ranges           = try(each.value.source_port_ranges, null)
  destination_port_ranges      = try(each.value.destination_port_ranges, null)
  source_address_prefixes      = try(each.value.source_address_prefixes, null)
  destination_address_prefixes = try(each.value.destination_address_prefixes, null)
  description                  = try(each.value.description, null)
}


resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = azurerm_network_security_group.this
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.id
}
