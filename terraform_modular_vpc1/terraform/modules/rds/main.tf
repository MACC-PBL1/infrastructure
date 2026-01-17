resource "aws_db_subnet_group" "rds" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = [
    var.private_subnet_ids[0],
    var.private_subnet_ids[1]
  ]

  tags = {
    Name = "${var.name_prefix}-rds-subnets"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.name_prefix}-aurora"

  engine      = "aurora-mysql"
  engine_mode = "provisioned"

  database_name   = var.db_name
  master_username = var.db_master_username
  master_password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_sg_id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = [
    "error",
    "general",
    "slowquery",
    "audit"
  ]

  tags = {
    Name = "${var.name_prefix}-aurora"
  }
}


resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = 3
  identifier         = "${var.name_prefix}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.aurora.engine

  tags = {
    Name = "${var.name_prefix}-aurora-${count.index}"
  }
}
