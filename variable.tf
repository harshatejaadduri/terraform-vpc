variable "cidr_block" {
  default =  "10.0.0.0/16"
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_cidr_block" {
  type = list(string)
}

variable "private_cidr_block" {
  type = list(string)
}

variable "database_cidr_block" {
  type = list(string)
}

variable "is_peering_requried" {
  default = false
}