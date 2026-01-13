output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.this.name
}

output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.this.arn
}
