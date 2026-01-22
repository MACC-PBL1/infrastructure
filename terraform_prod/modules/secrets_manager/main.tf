resource "aws_secretsmanager_secret" "this" {
  name        = "${var.name_prefix}-${var.secret_name}"
  description = var.description

  recovery_window_in_days = 7

  tags = {
    Name = "${var.name_prefix}-${var.secret_name}"
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.secret_value)
}
