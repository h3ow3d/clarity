/**
 * Clarity Infrastructure - Terraform Backend Configuration
 */

terraform {
  required_version = ">= 1.14.1"

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
    bucket = "stackgobrr-projects-terraform-state"
    key    = "clarity/terraform.tfstate"
    region = "eu-west-2"
  }
}
