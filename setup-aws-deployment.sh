#!/bin/bash
set -e

echo "🚀 Clarity AWS Deployment Setup"
echo "================================"
echo ""

# Get AWS Account ID
echo "📋 Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Create S3 bucket for Terraform state
echo "📦 Step 1: Creating S3 bucket for Terraform state..."
if aws s3 ls s3://clarity-terraform-state 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb s3://clarity-terraform-state --region us-east-1
    aws s3api put-bucket-versioning \
        --bucket clarity-terraform-state \
        --versioning-configuration Status=Enabled
    echo "✅ Created S3 bucket: clarity-terraform-state"
else
    echo "✅ S3 bucket already exists: clarity-terraform-state"
fi
echo ""

# Step 2: Check if OIDC provider exists
echo "🔐 Step 2: Setting up GitHub OIDC provider..."
OIDC_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text)

if [ -z "$OIDC_EXISTS" ]; then
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✅ Created GitHub OIDC provider"
else
    echo "✅ GitHub OIDC provider already exists"
fi
echo ""

# Step 3: Create IAM role for GitHub Actions
echo "👤 Step 3: Creating IAM role for GitHub Actions..."

cat > /tmp/github-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
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
EOF

if aws iam get-role --role-name GitHubActionsDeployRole-Clarity 2>&1 | grep -q 'NoSuchEntity'; then
    aws iam create-role \
        --role-name GitHubActionsDeployRole-Clarity \
        --assume-role-policy-document file:///tmp/github-trust-policy.json \
        --description "Role for GitHub Actions to deploy Clarity application"
    echo "✅ Created IAM role: GitHubActionsDeployRole-Clarity"
else
    echo "✅ IAM role already exists: GitHubActionsDeployRole-Clarity"
fi
echo ""

# Step 4: Attach permissions
echo "🔑 Step 4: Attaching permissions to IAM role..."

cat > /tmp/clarity-deploy-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:DeleteTable",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:ListTagsOfResource",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:UpdateTimeToLive",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:UpdateContinuousBackups"
      ],
      "Resource": "arn:aws:dynamodb:eu-west-2:${AWS_ACCOUNT_ID}:table/*-clarity-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:DeleteFunction",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:ListVersionsByFunction",
        "lambda:PublishVersion",
        "lambda:TagResource",
        "lambda:UntagResource"
      ],
      "Resource": "arn:aws:lambda:eu-west-2:${AWS_ACCOUNT_ID}:function:*-clarity-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "apigateway:*"
      ],
      "Resource": "arn:aws:apigateway:eu-west-2::/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/*-clarity-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:ListTagsLogGroup",
        "logs:ListTagsForResource",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ],
      "Resource": "arn:aws:logs:eu-west-2:${AWS_ACCOUNT_ID}:log-group:/aws/*clarity*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::stackgobrr-projects-terraform-state/clarity/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::stackgobrr-projects-terraform-state"
      ],
      "Condition": {
        "StringLike": {
          "s3:prefix": ["clarity/*"]
        }
      }
    }
  ]
}
EOF

POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='ClarityDeployPolicy'].Arn" --output text)

if [ -z "$POLICY_ARN" ]; then
    POLICY_ARN=$(aws iam create-policy \
        --policy-name ClarityDeployPolicy \
        --policy-document file:///tmp/clarity-deploy-policy.json \
        --query 'Policy.Arn' \
        --output text)
    echo "✅ Created IAM policy: ClarityDeployPolicy"
else
    echo "✅ IAM policy already exists: ClarityDeployPolicy"
fi

aws iam attach-role-policy \
    --role-name GitHubActionsDeployRole-Clarity \
    --policy-arn "$POLICY_ARN" 2>&1 || echo "✅ Policy already attached"

echo ""

# Clean up temp files
rm /tmp/github-trust-policy.json
rm /tmp/clarity-deploy-policy.json

# Output summary
echo "✅ Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Add this secret to your GitHub repository:"
echo "   Name:  AWS_DEPLOY_ROLE_ARN"
echo "   Value: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsDeployRole-Clarity"
echo ""
echo "2. Push your code to GitHub to trigger deployment:"
echo "   cd /Users/samholden/Git/personal/utils/clarity"
echo "   git push origin main"
echo ""
echo "3. Monitor deployment at:"
echo "   https://github.com/h3ow3d/clarity/actions"
echo ""
