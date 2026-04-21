# AWS Deployment Guide

This backend now supports two storage modes:

- `local`: SQLite + local filesystem
- `s3`: PostgreSQL + S3

## Step 1: Create these AWS resources

Create:

1. `Amazon RDS PostgreSQL`
2. `Amazon S3`
3. `Amazon ECR`
4. `Amazon ECS Fargate`
5. `Application Load Balancer`

Add later:

- `ElastiCache Redis`
- `CloudFront`
- `Secrets Manager`

## Step 2: Create S3 buckets

Create three private buckets in the same region:

- `sage-ai-raw`
- `sage-ai-audio`
- `sage-ai-artifacts`

## Step 3: Create PostgreSQL on RDS

Collect:

- DB host
- port
- database name
- username
- password

Use a connection string like:

```env
DATABASE_URL=postgresql+psycopg://USERNAME:PASSWORD@HOST:5432/DBNAME
```

## Step 4: Production env vars

Set these in ECS:

```env
APP_ENV=production
DEBUG=false
SECRET_KEY=replace-with-a-strong-random-secret
DATABASE_URL=postgresql+psycopg://USERNAME:PASSWORD@HOST:5432/DBNAME
REDIS_URL=redis://localhost:6379/0
STORAGE_PROVIDER=s3
AWS_REGION=us-east-1
S3_BUCKET_RAW=sage-ai-raw
S3_BUCKET_AUDIO=sage-ai-audio
S3_BUCKET_ARTIFACTS=sage-ai-artifacts
S3_PRESIGN_EXPIRY_SECONDS=3600
GROQ_API_KEY=replace-with-your-groq-key
GROQ_MODEL=llama-3.3-70b-versatile
FRONTEND_ORIGINS=https://your-frontend-domain.com
FRONTEND_ORIGIN_REGEX=
DEFAULT_MALE_VOICE=en-US-AndrewNeural
DEFAULT_FEMALE_VOICE=en-US-JennyNeural
```

If you run on ECS, use a task role for S3 instead of hardcoding AWS credentials.

## Step 5: ECS task role permissions

Grant the ECS task role:

- `s3:GetObject`
- `s3:PutObject`
- `s3:DeleteObject`

for those three buckets.

## Step 6: Build the image

```powershell
docker build -t sage-ai-backend ./backend
```

Push it to ECR and use that image in ECS.

## Step 7: ECS service

Recommended:

- one ECS service for API
- container port `8000`
- one ALB forwarding `80/443` to `8000`

## Step 8: First test after deploy

1. Open `/health`
2. Open `/docs`
3. Create a user
4. Upload a PDF or PPTX
5. Confirm the original file lands in `sage-ai-raw`
6. Confirm generated MP3s land in `sage-ai-audio`

## Step 9: Next production steps

After the first deploy works:

1. add Alembic migrations
2. replace local/background tasks with Celery workers
3. move secrets into Secrets Manager
4. put CloudFront in front of audio delivery
