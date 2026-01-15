output "parameter_arns" {
  description = "ARNs of the created SSM parameters"
  value       = { for k, v in aws_ssm_parameter.secrets : k => v.arn }
  sensitive   = true
}

output "parameter_names" {
  description = "Names of the created SSM parameters"
  value       = { for k, v in aws_ssm_parameter.secrets : k => v.name }
}

output "parameter_versions" {
  description = "Versions of the created SSM parameters"
  value       = { for k, v in aws_ssm_parameter.secrets : k => v.version }
}