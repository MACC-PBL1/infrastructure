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

###############################################
# ALB LISTENER (HTTP)
# 👉 ALB escucha en 80 y forwardea a HTTPS 443
###############################################

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

###############################################
# Target Groups (1 por EC2 / ASG)
# 👉 Backend SIEMPRE HTTPS :443 (HAProxy)
###############################################

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
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
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

###############################################
# Auth + Logs peer target groups (SIN CAMBIOS)
###############################################

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
  target_id        = each.value
  port             = 8080
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "logs_instances" {
  for_each = toset(var.logs_instance_ips)

  target_group_arn = aws_lb_target_group.logs.arn
  target_id        = each.value
  port             = 8080
  availability_zone = "all"
}

###############################################
# Listener rules (MULTI-PATH → MISMA EC2)
###############################################

locals {
  service_paths = flatten([
    for svc, cfg in var.microservices : [
      for p in cfg.paths : {
        service = svc
        path    = p
      }
    ]
  ])
}

resource "aws_lb_listener_rule" "ms" {
  for_each = {
    for idx, item in local.service_paths :
    "${item.service}-${idx}" => item
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + index(keys({
    for i, v in local.service_paths :
    "${v.service}-${i}" => v
  }), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ms[each.value.service].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }
}

###############################################
# Auth / Logs rules
###############################################

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
