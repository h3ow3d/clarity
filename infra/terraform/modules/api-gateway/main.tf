/**
 * API Gateway Module
 * Sets up REST API resources, methods, and integrations
 */

# /attempts resource
resource "aws_api_gateway_resource" "attempts" {
  rest_api_id = var.api_id
  parent_id   = var.root_resource_id
  path_part   = "attempts"
}

# /attempts/{id} resource
resource "aws_api_gateway_resource" "attempt_by_id" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.attempts.id
  path_part   = "{id}"
}

# /scenarios resource
resource "aws_api_gateway_resource" "scenarios" {
  rest_api_id = var.api_id
  parent_id   = var.root_resource_id
  path_part   = "scenarios"
}

# /scenarios/{id} resource
resource "aws_api_gateway_resource" "scenario_by_id" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.scenarios.id
  path_part   = "{id}"
}

# POST /attempts - Submit attempt
resource "aws_api_gateway_method" "post_attempts" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.attempts.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_attempts" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.attempts.id
  http_method             = aws_api_gateway_method.post_attempts.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.submit_attempt_arn}/invocations"
}

resource "aws_lambda_permission" "post_attempts" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.submit_attempt_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

# GET /attempts - List attempts
resource "aws_api_gateway_method" "get_attempts" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.attempts.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_attempts" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.attempts.id
  http_method             = aws_api_gateway_method.get_attempts.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.list_attempts_arn}/invocations"
}

resource "aws_lambda_permission" "get_attempts" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.list_attempts_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

# GET /attempts/{id} - Get attempt by ID
resource "aws_api_gateway_method" "get_attempt_by_id" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.attempt_by_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_attempt_by_id" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.attempt_by_id.id
  http_method             = aws_api_gateway_method.get_attempt_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.get_attempt_arn}/invocations"
}

resource "aws_lambda_permission" "get_attempt_by_id" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.get_attempt_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

# GET /scenarios - List scenarios
resource "aws_api_gateway_method" "get_scenarios" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.scenarios.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_scenarios" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.scenarios.id
  http_method             = aws_api_gateway_method.get_scenarios.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.list_scenarios_arn}/invocations"
}

resource "aws_lambda_permission" "get_scenarios" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.list_scenarios_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

# GET /scenarios/{id} - Get scenario by ID
resource "aws_api_gateway_method" "get_scenario_by_id" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.scenario_by_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_scenario_by_id" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.scenario_by_id.id
  http_method             = aws_api_gateway_method.get_scenario_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.get_scenario_arn}/invocations"
}

resource "aws_lambda_permission" "get_scenario_by_id" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.get_scenario_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

# CORS configuration for all methods
module "cors_attempts" {
  source = "../cors"

  api_id      = var.api_id
  resource_id = aws_api_gateway_resource.attempts.id
}

module "cors_attempt_by_id" {
  source = "../cors"

  api_id      = var.api_id
  resource_id = aws_api_gateway_resource.attempt_by_id.id
}

module "cors_scenarios" {
  source = "../cors"

  api_id      = var.api_id
  resource_id = aws_api_gateway_resource.scenarios.id
}

module "cors_scenario_by_id" {
  source = "../cors"

  api_id      = var.api_id
  resource_id = aws_api_gateway_resource.scenario_by_id.id
}

data "aws_region" "current" {}
