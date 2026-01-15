resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = var.iam_role_arn
    bucket_arn = var.s3_bucket_arn

    buffering_interval = 300
    buffering_size     = 5

    compression_format = "UNCOMPRESSED"
    file_extension     = ".json"
    
    prefix = "${var.prefix}/!{timestamp:yyyy/MM/dd}/"

    error_output_prefix = "errors/${var.prefix}/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${var.firehose_name}"
      log_stream_name = "S3Delivery"
    }
  }

  tags = var.tags
}
