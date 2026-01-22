variable "topic_name" {
  description = "Nombre del tema SNS"
  type        = string
  default     = "security-alerts" # Valor por defecto si no se especifica otro
}

variable "email_address" {
  description = "Correo electrónico para recibir las notificaciones"
  type        = string
}