
variable "prefix" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}
variable "address_space" {
  type = list(string)
}
variable "subnets" {
  type = any
}
