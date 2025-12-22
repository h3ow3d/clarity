output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.clarity.invoke_url
}

output "dynamodb_table_name" {
  description = "DynamoDB attempts table name"
  value       = aws_dynamodb_table.attempts.name
}

output "lambda_functions" {
  description = "Lambda function ARNs"
  value = {
    submit_attempt  = aws_lambda_function.submit_attempt.arn
    get_attempt     = aws_lambda_function.get_attempt.arn
    list_attempts   = aws_lambda_function.list_attempts.arn
    list_scenarios  = aws_lambda_function.list_scenarios.arn
    get_scenario    = aws_lambda_function.get_scenario.arn
  }
}
