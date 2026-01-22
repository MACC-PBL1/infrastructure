output "secret_name" {
  description = "Name of the SSL Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.name
}
