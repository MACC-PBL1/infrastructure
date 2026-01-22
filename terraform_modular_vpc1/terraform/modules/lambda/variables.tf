variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "handler" {
  description = "Handler de la función (ej: index.handler)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime del Lambda"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Timeout en segundos"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Memoria en MB"
  type        = number
  default     = 512
}

variable "source_code_path" {
  description = "Ruta al directorio con el código del Lambda"
  type        = string
}

variable "environment_variables" {
  description = "Variables de entorno para el Lambda"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 que triggerea el Lambda"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID del bucket S3"
  type        = string
}

variable "s3_filter_prefix" {
  description = "Prefijo para filtrar eventos S3 (ej: zeek/)"
  type        = string
  default     = ""
}

variable "s3_filter_suffix" {
  description = "Sufijo para filtrar eventos S3 (ej: .json)"
  type        = string
  default     = ""
}

variable "vpc_config" {
  description = "Configuración VPC para acceder a RDS"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "ssm_parameter_arns" {
  description = "ARNs de parámetros SSM que el Lambda puede leer"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}

variable "use_existing_role" {
  description = "Usar un rol IAM existente en lugar de crear uno nuevo"
  type        = bool
  default     = false
}

variable "existing_role_arn" {
  description = "ARN del rol IAM existente (requerido si use_existing_role = true)"
  type        = string
  default     = null
}

variable "enable_s3_trigger" {
  description = "Enable S3 trigger for Lambda"
  type        = bool
  default     = true
}