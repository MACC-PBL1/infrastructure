variable "secrets" {
  description = "Map of secrets to store in Parameter Store"
  type = map(object({
    description = string
    value       = string
  }))
}

variable "tags" {
  description = "Tags to apply to all secrets"
  type        = map(string)
  default     = {}
}