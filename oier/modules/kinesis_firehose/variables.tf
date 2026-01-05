variable "stream_name" {
  description = "Name of the Kinesis Firehose stream"
  type        = string
}

variable "role_arn" {
  description = "ARN of IAM role for Firehose (use existing LabRole)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the destination S3 bucket"
  type        = string
}

variable "s3_prefix" {
  description = "S3 prefix for logs"
  type        = string
  default     = ""
}

variable "buffering_size" {
  description = "Buffer size in MB"
  type        = number
  default     = 5
}

variable "buffering_interval" {
  description = "Buffer interval in seconds"
  type        = number
  default     = 300
}

variable "compression_format" {
  description = "Compression format"
  type        = string
  default     = "GZIP"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}