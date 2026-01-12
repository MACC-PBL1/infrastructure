###############################################
# INTERNAL ALB (PRIVATE) + LISTENER + RULES
###############################################

resource "aws_lb" "internal" {
  name               = substr("${var.name_prefix}-alb", 0, 32)
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK - ALB default"
      status_code  = "200"
    }
  }
}

# One target group per microservice
locals {
  tg_base_names = {
    for k, v in var.microservices :
    k => substr(
      replace("${var.name_prefix}-${k}", "/[^a-zA-Z0-9-]/", ""),
      0,
      28
    )
  }
}

resource "aws_lb_target_group" "ms" {
  for_each = var.microservices

  name        = "${local.tg_base_names[each.key]}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.name_prefix}-${each.key}-tg"
  }
}

# Listener rules (path-based routing)
resource "aws_lb_listener_rule" "ms" {
  for_each = var.microservices

  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + index(keys(var.microservices), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ms[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}
