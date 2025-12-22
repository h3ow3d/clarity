# Clarity — AI Critical Thinking Coach

An AI-driven web application that helps users improve critical thinking through structured scenarios, evaluation, and targeted practice. Powered by AWS Bedrock.

## Overview

**Clarity** evaluates responses to critical thinking questions using a structured rubric (clarity, logic, evidence, assumptions, etc.), provides feedback with actionable insights, and tracks user progress over time to recommend targeted exercises.

### Key Features

- 🎯 **Structured evaluation**: Multi-dimensional rubric with per-dimension scores (0–4) and overall score (0–100)
- 📊 **Progress tracking**: User profiles with moving averages, trends, and calibration metrics
- 🤖 **AI-powered feedback**: AWS Bedrock generates rubric scores and improvement suggestions
- 🎓 **Targeted practice**: Recommends exercises based on identified weaknesses

## Tech Stack

- **Frontend**: Vite + React + TypeScript + Recharts
- **Backend**: AWS Lambda (Node.js 20 + TypeScript) + API Gateway
- **AI**: AWS Bedrock (structured JSON outputs via Anthropic Claude or similar)
- **Data**: DynamoDB (Attempts, Profiles, Scenarios)
- **Auth**: AWS Cognito
- **Infrastructure**: Terraform
- **CI/CD**: GitHub Actions

## Repository Structure

```
/apps
  /web                 Frontend (Vite + React)
  /api                 Backend Lambda handlers
/infra
  /terraform           Infrastructure as code
/.github
  /workflows           CI/CD pipelines
/docs                  Architecture and design docs
/work-items            Planned tasks and epics
```

## Getting Started

### Prerequisites

- Node.js 20+ (use `.nvmrc`: `nvm use`)
- npm 10+
- AWS account with Bedrock access (for deployment)
- Terraform 1.6+ (for infrastructure)

### Installation

```bash
# Install dependencies
npm install

# Verify setup
npm run lint
npm run format:check
npm run type-check
```

### Development

```bash
# Run frontend dev server
cd apps/web
npm run dev

# Run API locally (requires AWS credentials)
cd apps/api
npm run build
```

### Pre-commit Hooks

Husky + lint-staged runs automatically on commit:

- ESLint with auto-fix
- Prettier formatting
- TypeScript type-check (per workspace)

To set up hooks after cloning:

```bash
npm install
npm run prepare
```

## Work Items

See [`/work-items/README.md`](./work-items/README.md) for planned tasks and implementation order.

Recommended starting point: [`00-repository-groundwork.md`](./work-items/00-repository-groundwork.md) ✅ (completed)

## Product Reference

See [`instructions.md`](./instructions.md) for the full product specification, architecture decisions, and engineering standards.

## Engineering Standards

- **Strict TypeScript**: No `any`, explicit return types, Zod validation
- **Least-privilege IAM**: All Lambda roles follow minimal permissions
- **Observability**: CloudWatch logs, metrics, and alarms for all services
- **Testing**: Unit tests with mocked AWS services, integration tests gated by env flags

## License

Private project — all rights reserved.
