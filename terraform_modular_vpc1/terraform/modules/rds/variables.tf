variable "name_prefix" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }
variable "db_name" { type = string }
variable "db_master_username" { type = string }

variable "db_instance_class" { type = string }
variable "db_master_password" {
  description = "Master password for Aurora RDS"
  type        = string
  sensitive   = true
}
