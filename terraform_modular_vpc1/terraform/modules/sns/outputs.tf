output "sns_topic_arn" {
  description = "ARN del tema SNS creado"
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "Nombre del tema SNS"
  value       = aws_sns_topic.this.name
}