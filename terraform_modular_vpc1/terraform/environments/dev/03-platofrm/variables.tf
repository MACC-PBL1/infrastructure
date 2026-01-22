###############################################
# VARIABLES - 03 PLATFORM
###############################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "pi-infra"
}

variable "username" {
  description = "Your username, used to create unique resource names."
  type        = string
  default     = "user"
}

# ============ EC2 Instance Types ============
variable "nat_bastion_instance_type" {
  description = "Instance type for NAT+Bastion instance (public subnet)"
  type        = string
  default     = "t2.micro"
}

variable "microservice_instance_type" {
  description = "Instance type for microservices instances (private subnets)"
  type        = string
  default     = "t2.micro"
}

# ============ SSH ============
variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "labsuser"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH (restrict this in production)"
  type        = string
  default     = "0.0.0.0/0"
}

# ============ Microservices ============
variable "microservices" {
  description = "Microservices definition. Key is service name."
  type = map(object({
    port         = number
    path_pattern = string
  }))
  default = {
    order-warehouse-microservice = {
        port = 8081
        path_pattern = "/order/*"
      }
      payment-delivery-microservice = {
        port = 8082
        path_pattern = "/payment/*"
      }
      machines-microservice = {
        port = 8083
        path_pattern = "/machines/*"
      }
  }
}


# ============ AutoScaling ============
variable "asg_min_size" {
  description = "Minimum instances per microservice ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired instances per microservice ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum instances per microservice ASG"
  type        = number
  default     = 4
}

variable "cpu_target_utilization" {
  description = "Target CPU utilization (%) for scaling policy"
  type        = number
  default     = 60
}

# ============ Database (Aurora MySQL) ============
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_master_username" {
  description = "Master username for Aurora"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t3.medium"
}

# ============ Tags ============
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "pi-infra"
    Environment = "development"
    ManagedBy   = "terraform"
    Team        = "MACC"
  }
}

variable "peer_vpc_cidr" {
  description = "CIDR block of the peer VPC"
  type        = string
}

# ============ ALB ============== 
variable "auth_instance_ips" {
  type = list(string)
}

variable "logs_instance_ips" {
  type = list(string)
}

variable "lab_role_arn" {
  description = "ARN del LabRole reutilizado por Firehose"
  type        = string
}

variable "email_subscription" {
  description = "Correo electrónico para recibir alertas de seguridad"
  type        = string
  default     = "gorka.fernandezg@alumni.mondragon.edu"
}