variable "bucket_name" {
  description = "Nombre del bucket S3 para logs"
  type        = string
}

variable "force_destroy" {
  description = "Permitir borrar el bucket aunque tenga objetos"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}
