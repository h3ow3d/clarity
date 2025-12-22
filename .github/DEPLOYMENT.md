# GitHub Actions Deployment Setup

## Prerequisites

1. **AWS Account** with permissions to create:
   - IAM roles
   - DynamoDB tables
   - Lambda functions
   - API Gateway
   - S3 buckets (for Terraform state)

2. **GitHub Repository** with Actions enabled

## Setup Instructions

### 1. Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://clarity-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket clarity-terraform-state \
  --versioning-configuration Status=Enabled
```

### 2. Create IAM OIDC Provider for GitHub Actions

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 3. Create IAM Role for GitHub Actions

Create a file `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:h3ow3d/clarity:*"
        }
      }
    }
  ]
}
```

Create the role:

```bash
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

### 4. Attach Permissions to the Role

```bash
# Attach AdministratorAccess for MVP (restrict in production!)
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Production Note:** Replace `AdministratorAccess` with a custom policy that only grants:

- DynamoDB: CreateTable, DescribeTable, UpdateTable, PutItem, GetItem, Query
- Lambda: CreateFunction, UpdateFunction, GetFunction, InvokeFunction
- API Gateway: CreateRestApi, CreateResource, PutMethod, CreateDeployment
- IAM: CreateRole, AttachRolePolicy (limited scope)
- S3: GetObject, PutObject (Terraform state bucket only)
- CloudWatch Logs: CreateLogGroup, PutLogEvents

### 5. Add GitHub Secret

1. Go to your repository: https://github.com/h3ow3d/clarity
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AWS_DEPLOY_ROLE_ARN`
5. Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsDeployRole`

Get your account ID with:

```bash
aws sts get-caller-identity --query Account --output text
```

### 6. Enable GitHub Actions

The workflow file `.github/workflows/deploy-mvp.yml` is already configured to:

- Trigger on pushes to `main` branch (changes to `apps/api/` or `infra/terraform/`)
- Can also be manually triggered via "Actions" tab → "Deploy Clarity MVP" → "Run workflow"

## Deployment Process

The workflow will:

1. ✅ Checkout code
2. ✅ Setup Node.js and install dependencies
3. ✅ Type check TypeScript code
4. ✅ Build Lambda functions
5. ✅ Configure AWS credentials (OIDC, no secrets!)
6. ✅ Initialize Terraform
7. ✅ Validate Terraform configuration
8. ✅ Plan infrastructure changes
9. ✅ Apply infrastructure changes
10. ✅ Output API endpoint URL

## Monitoring

- View deployment logs in the "Actions" tab
- Check the workflow summary for the API endpoint URL
- Monitor Lambda logs in CloudWatch: `/aws/lambda/dev-clarity-*`
- Monitor API Gateway logs: `/aws/apigateway/dev-clarity`

## Manual Deployment (Alternative)

If you prefer to deploy manually instead of using GitHub Actions:

```bash
# Build Lambda functions
cd apps/api
npm install
npm run build

# Deploy with Terraform
cd ../../infra/terraform
terraform init
terraform plan
terraform apply
```

## Cleanup

To destroy all AWS resources:

```bash
cd infra/terraform
terraform destroy
```

Or use the GitHub Actions workflow with a destroy step (add manually if needed).
