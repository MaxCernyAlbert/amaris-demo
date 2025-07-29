<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.112 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.112 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | List of CIDR blocks for the VNET address space. | `list(string)` | n/a | yes |
| <a name="input_ddos_plan_id"></a> [ddos\_plan\_id](#input\_ddos\_plan\_id) | Resource ID of an existing DDoS Standard plan. Used only when enable\_ddos = true. | `string` | `null` | no |
| <a name="input_enable_ddos"></a> [enable\_ddos](#input\_enable\_ddos) | If true, associates the VNET with an existing DDoS Standard plan (must supply ddos\_plan\_id). | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region (e.g., eastus). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | VNET name following naming convention, e.g., amaris-dev-eastus-vnet. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group where the VNET will be created. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnet definitions keyed by subnet logical name.<br/>Each subnet can optionally define service endpoints, delegations, and inline NSG rules.<br/>Example:<br/>{<br/>  app = {<br/>    address\_prefixes  = ["10.10.1.0/24"]<br/>    service\_endpoints = ["Microsoft.Storage"]<br/>    delegations = [{<br/>      name = "delegation1"<br/>      service\_delegation = {<br/>        name    = "Microsoft.Web/serverFarms"<br/>        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]<br/>      }<br/>    }]<br/>    nsg\_rules = [{<br/>      name                       = "allow\_ssh"<br/>      priority                   = 100<br/>      direction                  = "Inbound"<br/>      access                     = "Allow"<br/>      protocol                   = "Tcp"<br/>      source\_port\_range          = "*"<br/>      destination\_port\_range     = "22"<br/>      source\_address\_prefix      = "*"<br/>      destination\_address\_prefix = "*"<br/>    }]<br/>  }<br/>} | <pre>map(object({<br/>    address_prefixes  = list(string)<br/>    service_endpoints = optional(list(string), [])<br/>    delegations = optional(list(object({<br/>      name = string<br/>      service_delegation = object({<br/>        name    = string<br/>        actions = list(string)<br/>      })<br/>    })), [])<br/>    nsg_rules = optional(list(object({<br/>      name                       = string<br/>      priority                   = number<br/>      direction                  = string # Inbound or Outbound<br/>      access                     = string # Allow or Deny<br/>      protocol                   = string # Tcp | Udp | *<br/>      source_port_range          = string<br/>      destination_port_range     = string<br/>      source_address_prefix      = string<br/>      destination_address_prefix = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources created by this module. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | Map of subnet logical name to NSG ID (only for subnets with rules). |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet logical name to subnet ID. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Resource ID of the created VNET. |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Name of the created VNET. |
<!-- END_TF_DOCS -->

