# Tryognik Dashboard MVP

This repo contains a minimal React + TypeScript frontend and Node/Express backend to demo the Production Dashboard MVP for *The Tryognik – The Three Flames*.

Features:
- React + TypeScript (Vite) frontend
- Role-aware auth stub (Investor / CFO / Producer / Legal / Admin)
- KPI cards, Gantt placeholder, Tabs, Audit log
- CSV upload endpoint that parses a budget CSV and computes: burn rate, cash runway, and budget variance
- Simple API (POST /api/v1/upload/budget, GET /api/v1/metrics/overview)
- Docker Compose for local dev

Quick start (requires Node 18+ and Docker if using compose):

# Frontend
cd web
npm install
npm run dev

# Backend
cd api
npm install
npm run dev

# Local compose
docker compose up --build

Sample CSV: `api/sample_data/sample_budget.csv` (format described below)

Demo helper: GET `/api/v1/upload/load-sample` will load the included sample CSV into the metrics store for a quick demo (then refresh frontend overview).

CI & AWS notes

- The GitHub Actions CI builds both `web` and `api` on PRs and pushes, and will push Docker images to ECR when changes are pushed to `main`.
- Required GitHub secrets for the docker push step:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (e.g., us-east-1)
  - `AWS_ACCOUNT_ID` (your account id)
  - `ECR_REPO_WEB` (e.g., tryognik-web-repo)
  - `ECR_REPO_API` (e.g., tryognik-api-repo)

Infra: use `infra/ecs-fargate.yaml` as a starter to provision ECR repos and an ECS cluster in staging; add task definitions and ALB listeners per your VPC and security requirements.

