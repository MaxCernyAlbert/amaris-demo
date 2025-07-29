prefix = "amaris"
env    = "prod"
region = "westeurope"

tags = {
  env    = "prod"
  owner  = "platform"
  cost   = "prod"
  region = "westeurope"
}

address_space = ["10.20.0.0/16"]

subnets = {
  app = {
    address_prefixes  = ["10.20.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
    nsg_rules         = []
  },
  data = {
    address_prefixes = ["10.20.2.0/24"]
    nsg_rules        = []
  }
}
