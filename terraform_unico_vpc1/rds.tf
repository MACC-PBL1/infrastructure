###############################################
# RDS AURORA CLUSTER (1 writer + 2 readers)
###############################################

resource "aws_db_subnet_group" "rds" {
  name       = "${local.name_prefix}-rds-subnets"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  tags = {
    Name = "${local.name_prefix}-rds-subnets"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${local.name_prefix}-aurora"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  database_name           = var.db_name
  master_username         = var.db_master_username
  master_password         = var.db_master_password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "${local.name_prefix}-aurora"
  }
}

# 3 instances in the cluster (1 writer + 2 readers)
resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = 3
  identifier         = "${local.name_prefix}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.aurora.engine

  tags = {
    Name = "${local.name_prefix}-aurora-${count.index}"
  }
}
