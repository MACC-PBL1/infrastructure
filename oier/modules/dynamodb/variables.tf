variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "Hash key (partition key)"
  type        = string
}

variable "attributes" {
  description = "List of attributes"
  type = list(object({
    name = string
    type = string
  }))
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}