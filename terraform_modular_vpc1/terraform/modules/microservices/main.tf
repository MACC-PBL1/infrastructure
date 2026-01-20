###############################################
# MICROSERVICES - Launch Templates + ASGs + Scaling
###############################################

resource "aws_launch_template" "ms" {
  for_each = var.microservices

  name_prefix   = "${var.name_prefix}-${each.key}-lt-"
  image_id      = var.ami_id
  instance_type = var.microservice_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.microservices_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = each.key
      Role = "microservice"
      Svc  = each.key
    }
  }
}



resource "aws_autoscaling_group" "ms" {
  for_each = var.microservices

  name                      = "${var.name_prefix}-${each.key}-asg"
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 60

  vpc_zone_identifier = [
    var.private_subnet_ids[0],
    var.private_subnet_ids[1]
  ]

  launch_template {
    id      = aws_launch_template.ms[each.key].id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arns[each.key]]

  tag {
    key                 = "Name"
    value               = each.key
    propagate_at_launch = true
  }
}

# Target tracking scaling: CPU 목표 ~60%
resource "aws_autoscaling_policy" "cpu_target" {
  for_each = var.microservices

  name                   = "${var.name_prefix}-${each.key}-cpu-target"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.ms[each.key].name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_utilization
  }
}
