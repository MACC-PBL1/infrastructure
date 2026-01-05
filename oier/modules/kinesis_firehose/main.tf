resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = var.role_arn
    bucket_arn = var.s3_bucket_arn
    prefix     = var.s3_prefix

    buffering_size     = var.buffering_size
    buffering_interval = var.buffering_interval

    compression_format = var.compression_format

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${var.stream_name}"
      log_stream_name = "S3Delivery"
    }
  }

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${var.stream_name}"
  retention_in_days = 7

  tags = var.tags
}