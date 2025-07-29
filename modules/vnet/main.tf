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
}

resource "azurerm_subnet_delegation" "this" {
  for_each = {
    for k, v in var.subnets : k => v.delegations
    if length(try(v.delegations, [])) > 0
  }
  name      = "${var.name}-${each.key}-delegation"
  subnet_id = azurerm_subnet.this[each.key].id
  service_delegation {
    name    = each.value[0].service_delegation.name
    actions = each.value[0].service_delegation.actions
  }
}

resource "azurerm_network_security_group" "this" {
  for_each            = { for k, v in var.subnets : k => v.nsg_rules if length(try(v.nsg_rules, [])) > 0 }
  name                = "${var.name}-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = {
    for subnet_key, rules in var.subnets : subnet_key => rules.nsg_rules
    if length(try(rules.nsg_rules, [])) > 0
  }
  count = length(each.value)

  name                       = each.value[count.index].name
  priority                   = each.value[count.index].priority
  direction                  = each.value[count.index].direction
  access                     = each.value[count.index].access
  protocol                   = each.value[count.index].protocol
  source_port_range          = each.value[count.index].source_port_range
  destination_port_range     = each.value[count.index].destination_port_range
  source_address_prefix      = each.value[count.index].source_address_prefix
  destination_address_prefix = each.value[count.index].destination_address_prefix

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.key].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                 = azurerm_network_security_group.this
  subnet_id                = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.id
}
