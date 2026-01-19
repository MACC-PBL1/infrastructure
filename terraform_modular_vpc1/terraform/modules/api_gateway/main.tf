###############################################
# API GATEWAY (HTTP API) -> VPC LINK -> INTERNAL ALB
###############################################

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.name_prefix}-http-api"
  protocol_type = "HTTP"

  tags = {
    Name = "${var.name_prefix}-http-api"
  }
}

###############################################
# VPC Link
###############################################

resource "aws_apigatewayv2_vpc_link" "link" {
  name               = "${var.name_prefix}-vpc-link"
  security_group_ids = [var.vpc_link_sg_id]
  subnet_ids         = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

  tags = {
    Name = "${var.name_prefix}-vpc-link"
  }
}

###############################################
# Integration (ALB)
###############################################

resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.link.id

  integration_uri         = var.alb_listener_arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

###############################################
# Dynamic routes (MULTI-PATH)
###############################################

locals {
  api_paths = flatten([
    for svc, cfg in var.microservices : [
      for p in cfg.paths : {
        service = svc
        path    = replace(p, "/*", "/{proxy+}")
      }
    ]
  ])
}

resource "aws_apigatewayv2_route" "svc" {
  for_each = {
    for idx, item in local.api_paths :
    "${item.service}-${idx}" => item
  }

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

###############################################
# Default catch-all
###############################################

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

###############################################
# Stage
###############################################

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
