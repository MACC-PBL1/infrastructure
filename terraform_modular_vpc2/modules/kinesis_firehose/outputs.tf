output "stream_name" {
  description = "Name of the Firehose stream"
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "stream_arn" {
  description = "ARN of the Firehose stream"
  value       = aws_kinesis_firehose_delivery_stream.this.arn
}