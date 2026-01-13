# ============================================
# AWS Systems Manager Parameter Store
# Para gestión de secretos (SecOps Nivel 1)
# ============================================

resource "aws_ssm_parameter" "secrets" {
  for_each = var.secrets

  name        = each.key
  description = each.value.description
  type        = "SecureString"  # Encriptado con KMS por defecto
  value       = each.value.value

  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      SecOps    = "Nivel1"
    }
  )
}