output "vnet_id"      { description = "Resource ID of the created VNET."; value = azurerm_virtual_network.this.id }
output "vnet_name"    { description = "Name of the created VNET.";       value = azurerm_virtual_network.this.name }
output "subnet_ids"   { description = "Map of subnet logical name to subnet ID."; value = { for k, s in azurerm_subnet.this : k => s.id } }
output "nsg_ids"      { description = "Map of subnet logical name to NSG ID (only for subnets with rules)."; value = { for k, n in azurerm_network_security_group.this : k => n.id } }
