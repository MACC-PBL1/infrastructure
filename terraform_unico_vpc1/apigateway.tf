###############################################
# API GATEWAY (HTTP API) -> VPC LINK -> INTERNAL ALB
###############################################

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"

  tags = {
    Name = "${local.name_prefix}-http-api"
  }
}

# VPC Link uses private subnets (ENIs in your VPC)
resource "aws_apigatewayv2_vpc_link" "link" {
  name               = "${local.name_prefix}-vpc-link"
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  tags = {
    Name = "${local.name_prefix}-vpc-link"
  }
}

resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.link.id

  # Private integration to ALB (listener ARN)
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

# Routes: /svc1/{proxy+}, /svc2/{proxy+}, /svc3/{proxy+}
resource "aws_apigatewayv2_route" "svc" {
  for_each = var.microservices

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# Default catch-all
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
