# Clarity Infrastructure - Terraform Configuration

# MVP deployment for critical thinking evaluation platform

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Node.js 20+ and npm for building Lambda functions
- S3 bucket for Terraform state (create manually first)

## Setup

1. **Create S3 bucket for Terraform state:**

```bash
aws s3 mb s3://clarity-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket clarity-terraform-state \
  --versioning-configuration Status=Enabled
```

2. **Build Lambda functions:**

```bash
cd ../../apps/api
npm install
npm run build
```

3. **Initialize Terraform:**

```bash
terraform init
```

4. **Review the deployment plan:**

```bash
terraform plan
```

5. **Deploy the infrastructure:**

```bash
terraform apply
```

## Resources Created

- **DynamoDB Table**: `dev-clarity-attempts` with GSI for user queries
- **Lambda Functions**:
  - `dev-clarity-submit-attempt` - POST /attempts
  - `dev-clarity-get-attempt` - GET /attempts/{id}
  - `dev-clarity-list-attempts` - GET /attempts
  - `dev-clarity-list-scenarios` - GET /scenarios
  - `dev-clarity-get-scenario` - GET /scenarios/{id}
- **API Gateway**: REST API with CORS enabled
- **IAM Roles**: Lambda execution role with DynamoDB and Bedrock permissions
- **CloudWatch Logs**: API Gateway and Lambda logs

## Configuration

Default values:

- `aws_region`: us-east-1
- `environment`: dev

Override with:

```bash
terraform apply -var="environment=prod" -var="aws_region=us-west-2"
```

## Outputs

After deployment, Terraform will output:

- `api_endpoint`: API Gateway URL (use this in frontend)
- `dynamodb_table_name`: DynamoDB table name
- `lambda_functions`: ARNs of all Lambda functions

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Notes

- The S3 backend configuration stores state remotely for team collaboration
- Lambda functions are deployed from the compiled TypeScript code in `apps/api/dist`
- API Gateway uses AWS_PROXY integration for Lambda
- CORS is enabled for local frontend development
- For MVP, authentication is disabled (add Cognito later)
