locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.username}"

  az1 = data.aws_availability_zones.available.names[0]
  az2 = data.aws_availability_zones.available.names[1]
}
