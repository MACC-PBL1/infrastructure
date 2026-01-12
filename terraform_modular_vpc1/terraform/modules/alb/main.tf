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

resource "aws_lb_target_group" "auth" {
  name        = "auth-peer-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "logs" {
  name        = "logs-peer-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group_attachment" "auth_instances" {
  for_each = toset(var.auth_instance_ips)

  target_group_arn = aws_lb_target_group.auth.arn
  target_id        = each.value   # IP PRIVADA
  port             = 8080

  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "logs_instances" {
  for_each = toset(var.logs_instance_ips)

  target_group_arn = aws_lb_target_group.logs.arn
  target_id        = each.value   # IP PRIVADA
  port             = 80

  availability_zone = "all"
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

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = ["/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "logs" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 6

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.logs.arn
  }

  condition {
    path_pattern {
      values = ["/logs/*"]
    }
  }
}
