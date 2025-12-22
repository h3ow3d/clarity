/**
 * Clarity Infrastructure - Main Terraform Configuration
 * MVP deployment with DynamoDB, Lambda, and API Gateway
 */

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket = "clarity-terraform-state"
    key    = "clarity/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "clarity"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# DynamoDB table for attempts
resource "aws_dynamodb_table" "attempts" {
  name           = "${var.environment}-clarity-attempts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "attemptId"

  attribute {
    name = "attemptId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # GSI for querying user's attempts by timestamp
  global_secondary_index {
    name            = "userId-timestamp-index"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.environment}-clarity-attempts"
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-clarity-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda DynamoDB policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.environment}-clarity-lambda-dynamodb"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.attempts.arn,
          "${aws_dynamodb_table.attempts.arn}/index/*"
        ]
      }
    ]
  })
}

# Lambda Bedrock policy
resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "${var.environment}-clarity-lambda-bedrock"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      }
    ]
  })
}

# Build Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../apps/api/dist"
  output_path = "${path.module}/lambda-deployment.zip"
}

# Lambda function for submitting attempts
resource "aws_lambda_function" "submit_attempt" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-clarity-submit-attempt"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "handlers/attempts/submit.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      ATTEMPTS_TABLE_NAME = aws_dynamodb_table.attempts.name
      BEDROCK_MODEL_ID    = "anthropic.claude-3-sonnet-20240229-v1:0"
      AWS_REGION          = var.aws_region
    }
  }
}

# Lambda function for getting attempt
resource "aws_lambda_function" "get_attempt" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-clarity-get-attempt"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "handlers/attempts/get.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 10
  memory_size     = 256

  environment {
    variables = {
      ATTEMPTS_TABLE_NAME = aws_dynamodb_table.attempts.name
      AWS_REGION          = var.aws_region
    }
  }
}

# Lambda function for listing attempts
resource "aws_lambda_function" "list_attempts" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-clarity-list-attempts"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "handlers/attempts/list.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 10
  memory_size     = 256

  environment {
    variables = {
      ATTEMPTS_TABLE_NAME = aws_dynamodb_table.attempts.name
      AWS_REGION          = var.aws_region
    }
  }
}

# Lambda function for listing scenarios
resource "aws_lambda_function" "list_scenarios" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-clarity-list-scenarios"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "handlers/scenarios/list.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 5
  memory_size     = 256

  environment {
    variables = {
      AWS_REGION = var.aws_region
    }
  }
}

# Lambda function for getting scenario
resource "aws_lambda_function" "get_scenario" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-clarity-get-scenario"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "handlers/scenarios/get.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 5
  memory_size     = 256

  environment {
    variables = {
      AWS_REGION = var.aws_region
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "clarity" {
  name        = "${var.environment}-clarity-api"
  description = "Clarity API - Critical thinking evaluation platform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway resources and methods
module "api_gateway" {
  source = "./modules/api-gateway"

  api_id               = aws_api_gateway_rest_api.clarity.id
  root_resource_id     = aws_api_gateway_rest_api.clarity.root_resource_id
  api_execution_arn    = aws_api_gateway_rest_api.clarity.execution_arn
  environment          = var.environment
  
  # Lambda function ARNs
  submit_attempt_arn   = aws_lambda_function.submit_attempt.arn
  get_attempt_arn      = aws_lambda_function.get_attempt.arn
  list_attempts_arn    = aws_lambda_function.list_attempts.arn
  list_scenarios_arn   = aws_lambda_function.list_scenarios.arn
  get_scenario_arn     = aws_lambda_function.get_scenario.arn

  # Lambda function names for invoke permissions
  submit_attempt_name  = aws_lambda_function.submit_attempt.function_name
  get_attempt_name     = aws_lambda_function.get_attempt.function_name
  list_attempts_name   = aws_lambda_function.list_attempts.function_name
  list_scenarios_name  = aws_lambda_function.list_scenarios.function_name
  get_scenario_name    = aws_lambda_function.get_scenario.function_name
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "clarity" {
  rest_api_id = aws_api_gateway_rest_api.clarity.id

  depends_on = [module.api_gateway]

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      module.api_gateway,
      aws_lambda_function.submit_attempt.source_code_hash,
      aws_lambda_function.get_attempt.source_code_hash,
      aws_lambda_function.list_attempts.source_code_hash,
      aws_lambda_function.list_scenarios.source_code_hash,
      aws_lambda_function.get_scenario.source_code_hash,
    ]))
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "clarity" {
  deployment_id = aws_api_gateway_deployment.clarity.id
  rest_api_id   = aws_api_gateway_rest_api.clarity.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.environment}-clarity"
  retention_in_days = 7
}
