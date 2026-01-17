# =========================
# 1. Empaquetar código Lambda
# =========================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_code_path
  output_path = "${path.module}/../../lambda_packages/${var.function_name}.zip"
}

# =========================
# 2. Función Lambda
# =========================
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role = var.use_existing_role ? var.existing_role_arn : aws_iam_role.lambda_role[0].arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Configuración VPC (si se proporciona)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Variables de entorno
  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

# =========================
# 3. Permiso para S3
# =========================
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# =========================
# 4. S3 Bucket Notification
# =========================
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.s3_filter_prefix
    filter_suffix       = var.s3_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# =========================
# 5. IAM Role para Lambda (solo si no se usa rol existente)
# =========================
resource "aws_iam_role" "lambda_role" {
  count = var.use_existing_role ? 0 : 1

  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# =========================
# 6. Políticas IAM básicas (solo si no se usa rol existente)
# =========================

# Logs de CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  count      = var.use_existing_role ? 0 : 1
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Acceso VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.use_existing_role ? 0 : (var.vpc_config != null ? 1 : 0)
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# =========================
# 7. Política personalizada (solo si no se usa rol existente)
# =========================
resource "aws_iam_role_policy" "lambda_custom" {
  count = var.use_existing_role ? 0 : 1
  
  name = "${var.function_name}-custom-policy"
  role = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            var.s3_bucket_arn,
            "${var.s3_bucket_arn}/*"
          ]
        }
      ],
      length(var.ssm_parameter_arns) > 0 ? [
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameters"
          ]
          Resource = var.ssm_parameter_arns
        }
      ] : []
    )
  })
}