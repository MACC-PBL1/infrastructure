resource "aws_kms_key" "this" {
  description             = "KMS key for RDS Aurora encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.name_prefix}-kms-rds"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.this.key_id
}
