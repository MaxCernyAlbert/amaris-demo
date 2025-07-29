
variable "prefix" {}
variable "env" {}
variable "region" {}
variable "tags" {
  type = map(string)
}
variable "address_space" {
  type = list(string)
}
variable "subnets" {
  type = any
}
