variable "name_prefix" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "description" {
  type = string
}

variable "secret_value" {
  type      = map(any)
  sensitive = true
}
