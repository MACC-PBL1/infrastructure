###############################################
# DEV - 03 PLATFORM (after network + peering)
###############################################

terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# =========================
# Remote states (network + peering)
# =========================
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

# Optional: only to force dependency / visibility of peering outputs.
# (Not strictly required if 03-platform doesn't need peering id directly.)
#data "terraform_remote_state" "peering" {
#  backend = "local"
#  config = {
#    path = "../02-peering/terraform.tfstate"
#  }
#}

# =========================
# AMIs
# =========================
# Debian 12 for NAT+Bastion
data "aws_ami" "debian_12" {
  most_recent = true
  owners      = ["136693071363"] # Debian official

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Ubuntu 22.04 for microservices
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =========================
# Locals
# =========================
locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.username}"
}

# =========================
# Security Groups
# =========================
module "security_groups" {
  source = "../../../modules/security_groups"

  name_prefix      = local.name_prefix
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.network.outputs.vpc_cidr
  peer_vpc_cidr    = var.peer_vpc_cidr   # 👈 AÑADIR
  microservices    = var.microservices
  allowed_ssh_cidr = var.allowed_ssh_cidr
}


# =========================
# NAT + Bastion
# =========================
module "nat_bastion" {
  source = "../../../modules/nat_bastion"

  name_prefix               = local.name_prefix
  ami_id                    = data.aws_ami.debian_12.id
  nat_bastion_instance_type = var.nat_bastion_instance_type
  key_pair_name             = var.key_pair_name

  public_subnet_id       = data.terraform_remote_state.network.outputs.public_subnet_id
  nat_sg_id              = module.security_groups.nat_sg_id
  private_route_table_id = data.terraform_remote_state.network.outputs.private_route_table_id
}

# =========================
# ALB (internal)
# =========================
module "alb" {
  source = "../../../modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  microservices      = var.microservices
  auth_instance_ips = var.auth_instance_ips
  logs_instance_ips = var.logs_instance_ips
}

# =========================
# Microservices (ASGs)
# =========================

# =========================
# Microservices (ASGs)
# =========================
module "microservices" {
  source = "../../../modules/microservices"

  name_prefix                = local.name_prefix
  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids         = data.terraform_remote_state.network.outputs.private_subnet_ids
  microservices_sg_id        = module.security_groups.microservices_sg_id

  ami_id                     = data.aws_ami.ubuntu.id
  microservice_instance_type = var.microservice_instance_type
  key_pair_name              = var.key_pair_name

  microservices              = var.microservices
  target_group_arns          = module.alb.target_group_arns

  asg_min_size               = var.asg_min_size
  asg_max_size               = var.asg_max_size
  asg_desired_capacity       = var.asg_desired_capacity
  cpu_target_utilization     = var.cpu_target_utilization
}

resource "random_password" "rds_master" {
  length  = 20
  special = true

  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~"
}

# =========================
# KMS (for RDS encryption)
# =========================
module "kms_rds" {
  source = "../../../modules/kms"

  name_prefix = local.name_prefix
}

# =========================
# RDS (Aurora)
# =========================
module "rds" {
  source = "../../../modules/rds"

  name_prefix        = local.name_prefix
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id

  db_name            = var.db_name
  db_master_username = var.db_master_username
  db_master_password = random_password.rds_master.result
  db_instance_class  = var.db_instance_class

  kms_key_arn = module.kms_rds.kms_key_arn
}


# =========================
# SecOps - Secrets (SSM Parameter Store)
# =========================
module "secrets" {
  source = "../../../modules/secrets"

  secrets = {
    "/${local.name_prefix}/rds/master_password" = {
      description = "Master password for Aurora RDS"
      value       = random_password.rds_master.result
    }
  }

  tags = var.common_tags
}



# =========================
# API Gateway -> VPC Link -> ALB
# =========================
module "api_gateway" {
  source = "../../../modules/api_gateway"

  name_prefix        = local.name_prefix
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_link_sg_id     = module.security_groups.alb_sg_id

  alb_listener_arn   = module.alb.listener_arn
  microservices      = var.microservices
}

# =========================
# Logging - S3 + Firehose
# =========================

module "logs_s3" {
  source = "../../../modules/s3"

  bucket_name = "${local.name_prefix}-zeek-logs-2"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.username
  }
}

module "firehose_zeek" {
  source = "../../../modules/firehose"

  firehose_name  = "${local.name_prefix}-zeek-firehose"

  s3_bucket_name = module.logs_s3.bucket_name
  s3_bucket_arn  = module.logs_s3.bucket_arn

  iam_role_arn = var.lab_role_arn
  prefix       = "zeek"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.username
    LogSource   = "zeek"
  }
}

module "firehose_zeekflowmeter" {
  source = "../../../modules/firehose"

  firehose_name  = "${local.name_prefix}-zeekflowmeter-firehose"

  s3_bucket_name = module.logs_s3.bucket_name
  s3_bucket_arn  = module.logs_s3.bucket_arn

  iam_role_arn = var.lab_role_arn
  prefix       = "zeekflowmeter"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.username
    LogSource   = "zeekflowmeter"
  }
}

# =========================
# Grafana Monitoring
# =========================
module "grafana" {
  source = "../../../modules/grafana"

  name_prefix      = local.name_prefix
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_id        = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  ami_id           = data.aws_ami.ubuntu.id
  instance_type    = "t3.small"  # Ajusta según necesidad
  key_pair_name    = var.key_pair_name
  nat_sg_id        = module.security_groups.nat_sg_id
}

# =========================
# Lambda - Logs to Database
# =========================
module "lambda_logs_to_db" {
  source = "../../../modules/lambda"

  function_name    = "${local.name_prefix}-logs-to-db"
  source_code_path = "${path.module}/lambda_functions/logs_to_db"
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 1024

  # USAR LABROLE EXISTENTE (AWS Academy)
  use_existing_role  = true
  existing_role_arn  = var.lab_role_arn

  s3_bucket_arn    = module.logs_s3.bucket_arn
  s3_bucket_id     = module.logs_s3.bucket_name
  s3_filter_prefix = "zeek/"
  s3_filter_suffix = ""

  vpc_config = {
    subnet_ids         = data.terraform_remote_state.network.outputs.private_subnet_ids
    security_group_ids = [module.security_groups.microservices_sg_id]
  }

  environment_variables = {
    DB_HOST           = module.rds.writer_endpoint
    DB_PORT           = "3306"
    DB_NAME           = var.db_name
    DB_USER           = var.db_master_username
    DB_PASSWORD_PARAM = "/${local.name_prefix}/rds/master_password"
  }

  # Ya no necesitamos ssm_parameter_arns porque LabRole ya tiene esos permisos
  
  tags = var.common_tags

  depends_on = [
    module.rds,
    module.logs_s3
  ]
}

# =========================
# Lambda - Zeek Logs Merger
# =========================

# Create S3 folders for log merger (if using same bucket)
resource "aws_s3_object" "log_merger_folders" {
  for_each = toset([
    "conn/",
    "flowmeter/",
    "processed/",
    "merged-logs/",
    "state/"
  ])

  bucket  = module.logs_s3.bucket_name
  key     = each.value
  content = ""
}

module "lambda_zeek_merger" {
  source = "../../../modules/lambda"

  function_name    = "${local.name_prefix}-zeek-logs-merger"
  source_code_path = "${path.module}/lambda_functions/zeek_logs_merger"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512

  use_existing_role  = true
  existing_role_arn  = var.lab_role_arn

  # Dummy S3 values (required by module but won't be used for trigger)
  s3_bucket_arn    = module.logs_s3.bucket_arn
  s3_bucket_id     = module.logs_s3.bucket_name
  s3_filter_prefix = "dummy/"
  s3_filter_suffix = ""

  environment_variables = {
    BUCKET_NAME = module.logs_s3.bucket_name
  }

  tags = var.common_tags
}

# CloudWatch Log Group for merger
resource "aws_cloudwatch_log_group" "zeek_merger" {
  name              = "/aws/lambda/${module.lambda_zeek_merger.function_name}"
  retention_in_days = 7
  tags              = var.common_tags
}

# EventBridge Rule (every 5 minutes)
resource "aws_cloudwatch_event_rule" "zeek_merger_schedule" {
  name                = "${local.name_prefix}-zeek-merger-schedule"
  description         = "Trigger Zeek log merger every 1 minutes"
  schedule_expression = "rate(1 minutes)"
  tags                = var.common_tags
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "zeek_merger" {
  rule      = aws_cloudwatch_event_rule.zeek_merger_schedule.name
  target_id = "ZeekLogsMerger"
  arn       = module.lambda_zeek_merger.function_arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_merger" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_zeek_merger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.zeek_merger_schedule.arn
}

# ========================================================
# Lambda - Exfiltration Detector (Implementation from PDF)
# ========================================================

# 1. SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-security-alerts"
  tags = var.common_tags
}

# 2. Upload Layer Zip to S3 (SOLUCIÓN AL ERROR DE TAMAÑO)
resource "aws_s3_object" "layer_zip" {
  bucket = module.logs_s3.bucket_name
  key    = "layers/dependencies.zip"
  source = "${path.module}/layers/dependencies.zip"
  
  # Esto detecta si el archivo cambió para volver a subirlo
  etag   = filemd5("${path.module}/layers/dependencies.zip") 
}

# 3. Create Lambda Layer from S3
resource "aws_lambda_layer_version" "exfiltration_deps" {
  # En lugar de subirlo directo (filename), apuntamos a S3
  s3_bucket           = module.logs_s3.bucket_name
  s3_key              = aws_s3_object.layer_zip.key
  s3_object_version   = aws_s3_object.layer_zip.version_id

  layer_name          = "${local.name_prefix}-exfiltration-deps"
  compatible_runtimes = ["python3.11"]
  description         = "Dependencies: pandas, numpy, joblib"
}

# 4. Lambda Module Call
module "lambda_exfiltration_detector" {
  source = "../../../modules/lambda"

  function_name    = "${local.name_prefix}-exfiltration-detector"
  source_code_path = "${path.module}/lambda_functions/exfiltration_detector"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 1024

  use_existing_role = true
  existing_role_arn = var.lab_role_arn

  layers = [aws_lambda_layer_version.exfiltration_deps.arn]

  # Configuración del Trigger S3
  s3_bucket_arn     = module.logs_s3.bucket_arn
  s3_bucket_id      = module.logs_s3.bucket_name
  enable_s3_trigger = true
  s3_filter_prefix  = "merged-logs/"
  s3_filter_suffix  = ".csv"

  environment_variables = {
    MODEL_BUCKET  = module.logs_s3.bucket_name 
    SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
  }

  sns_topic_arn = aws_sns_topic.alerts.arn

  tags = var.common_tags

  depends_on = [
    module.logs_s3,
    module.lambda_zeek_merger,
    aws_s3_object.layer_zip # Esperar a que se suba el zip
  ]
}



provider "aws" {
  region = "us-east-1"
}

# Llamada al módulo SNS
module "security_notifications" {
  source = "../../../modules/sns"

  # Pasamos los valores a las variables definidas en variables.tf
  topic_name    = "security-alerts"
  #email_address = "gorka.fernandezg@alumni.mondragon.edu"
  email_address = "oier.fernandezg@alumni.mondragon.edu"
}

