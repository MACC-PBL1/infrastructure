###############################################
# RDS AURORA CLUSTER (1 writer + 2 readers)
###############################################

#Lee desde Parameter Store 
#data "aws_ssm_parameter" "db_password" {
#  name            = "/popbl-grupo1/dev/rds/master_password"
#  with_decryption = true
#}

#IMPORTANTE: Crear el secreto PRIMERO
#Antes de hacer terraform apply, el compañero debe crear el secreto:
#bash# El compañero ejecuta esto UNA SOLA VEZ:
# aws ssm put-parameter \
#  --name "/popbl-grupo1/dev/rds/master_password" \
#  --value "password" \
#  --type "SecureString" \
#  --description "Master password for Aurora RDS cluster" \
#  --region us-east-1 \
#  --profile default


resource "aws_db_subnet_group" "rds" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

  tags = {
    Name = "${var.name_prefix}-rds-subnets"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.name_prefix}-aurora"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  database_name           = var.db_name
  master_username         = var.db_master_username
  master_password         = "admin123" #data.aws_ssm_parameter.db_password.value 
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [var.rds_sg_id]
  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "${var.name_prefix}-aurora"
  }
}

# 3 instances in the cluster (1 writer + 2 readers)
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
