variable "api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "root_resource_id" {
  description = "API Gateway root resource ID"
  type        = string
}

variable "api_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "submit_attempt_arn" {
  description = "Submit attempt Lambda function ARN"
  type        = string
}

variable "get_attempt_arn" {
  description = "Get attempt Lambda function ARN"
  type        = string
}

variable "list_attempts_arn" {
  description = "List attempts Lambda function ARN"
  type        = string
}

variable "list_scenarios_arn" {
  description = "List scenarios Lambda function ARN"
  type        = string
}

variable "get_scenario_arn" {
  description = "Get scenario Lambda function ARN"
  type        = string
}

variable "submit_attempt_name" {
  description = "Submit attempt Lambda function name"
  type        = string
}

variable "get_attempt_name" {
  description = "Get attempt Lambda function name"
  type        = string
}

variable "list_attempts_name" {
  description = "List attempts Lambda function name"
  type        = string
}

variable "list_scenarios_name" {
  description = "List scenarios Lambda function name"
  type        = string
}

variable "get_scenario_name" {
  description = "Get scenario Lambda function name"
  type        = string
}
