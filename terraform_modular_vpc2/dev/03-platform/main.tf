data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}

# ============================================
# Security Groups
# ============================================
module "security" {
  source = "../../../modules/security/security_groups"

  name             = var.project_name
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# ============================================
# EC2 - AZ1 Public
# ============================================
module "ec2_az1_public" {
  source = "../../../modules/ec2"

  ami      = var.ami_id
  sg_id    = module.security.micro_sg_id
  key_name = var.key_pair_name

  instances = {
    "${var.project_name}-Opensource-Honeypot" = {
      instance_type = var.instance_type_public
      subnet_id     = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
      public_ip     = true
    }

    "${var.project_name}-Custom-Honeypot" = {
      instance_type = var.instance_type_public
      subnet_id     = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
      public_ip     = true
    }
  }
}

# ============================================
# EC2 - AZ1 Private
# ============================================
module "ec2_az1_private" {
  source = "../../../modules/ec2"

  ami      = var.ami_id
  sg_id    = module.security.micro_sg_id
  key_name = var.key_pair_name

  instances = {
    "${var.project_name}-Consul" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
      public_ip     = false
    }

    "${var.project_name}-RabbitMQ" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
      public_ip     = false
    }

    "${var.project_name}-Auth-Log-Microservice" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
      public_ip     = false
    }
  }
}

# ============================================
# EC2 - AZ2 Private
# ============================================
module "ec2_az2_private" {
  source = "../../../modules/ec2"

  ami      = var.ami_id
  sg_id    = module.security.micro_sg_id
  key_name = var.key_pair_name

  instances = {
    "${var.project_name}-Consul-2" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[1]
      public_ip     = false
    }

    "${var.project_name}-RabbitMQ-2" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[1]
      public_ip     = false
    }

    "${var.project_name}-Auth-Log-Microservice-2" = {
      instance_type = var.instance_type_private
      subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[1]
      public_ip     = false
    }
  }
}

# ============================================
# S3 Logs
# ============================================
module "s3_logs" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-logs"
  versioning_enabled = false

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-logs-bucket" }
  )
}

# ============================================
# Kinesis Firehose - Honeypots
# ============================================
module "firehose_honeypots" {
  source = "../../../modules/kinesis_firehose"

  stream_name    = "${var.project_name}-honeypots-stream"
  role_arn       = var.firehose_role_arn
  s3_bucket_arn  = module.s3_logs.bucket_arn
  s3_prefix      = "honeypots/"

  buffering_size     = 5
  buffering_interval = 300
  compression_format = "GZIP"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-honeypots-firehose"
      Type = "honeypots"
    }
  )
}

# ============================================
# Kinesis Firehose - Microservices
# ============================================
module "firehose_microservices" {
  source = "../../../modules/kinesis_firehose"

  stream_name    = "${var.project_name}-microservices-stream"
  role_arn       = var.firehose_role_arn
  s3_bucket_arn  = module.s3_logs.bucket_arn
  s3_prefix      = "microservices/"

  buffering_size     = 5
  buffering_interval = 300
  compression_format = "GZIP"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-microservices-firehose"
      Type = "microservices"
    }
  )
}

# ============================================
# DynamoDB
# ============================================
module "dynamodb" {
  source = "../../../modules/dynamodb"

  table_name   = "${var.project_name}-table"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "event_id"

  attributes = [
    {
      name = "event_id"
      type = "S"
    }
  ]

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-dynamodb" }
  )
}
