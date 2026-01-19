output "function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  value = var.use_existing_role ? var.existing_role_arn : aws_iam_role.lambda_role[0].arn
}

output "invoke_arn" {
  description = "ARN para invocar el Lambda"
  value       = aws_lambda_function.this.invoke_arn
}