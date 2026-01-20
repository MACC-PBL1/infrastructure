output "rds_endpoint" {
  description = "RDS endpoint (hostname)"
  value       = aws_db_instance.this.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "rds_db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}
