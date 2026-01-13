variable "prefix" {
  description = "Prefijo S3 para los logs (ej: zeek/, zeekflowmeter/)"
  type        = string
}

variable "firehose_name" {
  description = "Nombre del Kinesis Firehose"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 destino"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 destino"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN del rol IAM existente (LabRole)"
  type        = string
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}
