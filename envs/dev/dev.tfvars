prefix = "amaris"
env    = "dev"
region = "eastus"

tags = {
  env    = "dev"
  owner  = "platform"
  cost   = "dev"
  region = "eastus"
}

address_space = ["10.10.0.0/16"]

subnets = {
  app = {
    address_prefixes  = ["10.10.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
    nsg_rules = [
      {
        name                       = "allow_ssh"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  data = {
    address_prefixes = ["10.10.2.0/24"]
  }
}
