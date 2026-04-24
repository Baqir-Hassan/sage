# AWS Free-Tier Launch Guide

This guide is focused on the cheapest practical AWS launch path for Sage.

## Recommended Starter Architecture

Use these AWS services first:

- `EC2` for the FastAPI API and the background worker on the same instance
- `S3` for uploaded notes and generated audio
- `SQS` for background document processing jobs
- `RDS PostgreSQL` if it fits your free-tier/credits, otherwise keep the database on the EC2 instance for the earliest launch

Avoid at the start:

- `ECS Fargate`
- `ElastiCache`
- `Step Functions`
- `CloudFront`
- `Secrets Manager`

Those are useful later, but they increase cost and operational complexity too early.

## Step 1: Create AWS resources

Create:

1. one `EC2` instance
2. one `SQS` queue for document processing
3. one dead-letter queue for failed jobs
4. three private `S3` buckets, or one private bucket with prefixes
5. optionally one `RDS PostgreSQL` database

Recommended bucket names:

- `sage-ai-raw`
- `sage-ai-audio`
- `sage-ai-artifacts`

## Step 2: Configure environment variables

Set these in production:

```env
APP_ENV=production
DEBUG=false
SECRET_KEY=replace-with-a-strong-random-secret
DATABASE_URL=postgresql+psycopg://USERNAME:PASSWORD@HOST:5432/DBNAME
QUEUE_PROVIDER=sqs
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/sage-document-processing
SQS_REGION=us-east-1
SQS_WAIT_TIME_SECONDS=20
SQS_MAX_MESSAGES=1
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

A production-ready example file is available at [`.env.production.example`](./.env.production.example).

If you are launching as cheaply as possible, you can temporarily keep a local database on EC2 and use:

```env
DATABASE_URL=sqlite:///./app.db
```

That is acceptable for a first low-traffic launch, but PostgreSQL should be the next upgrade.

## Step 3: Attach IAM permissions

Give the EC2 instance role permission to:

- send and receive SQS messages
- delete SQS messages
- read and write S3 objects
- delete S3 objects

This is better than hardcoding AWS credentials into `.env`.

## Step 4: Deploy the API

From the repository root:

```powershell
docker build -t sage-ai-backend ./backend
```

You can deploy with Docker on EC2 or install Python directly on the instance.

Before starting the API for the first time, run:

```powershell
./scripts/run_migrations.sh
```

Run the API with:

```powershell
./scripts/start_api.sh
```

## Step 5: Deploy the worker

Run the worker on the same EC2 instance:

```powershell
./scripts/start_sqs_worker.sh
```

The API writes jobs to SQS, and this worker consumes them.

Currently queued operations include:

- document ingestion after upload
- lecture audio generation
- lecture content regeneration

Launch safeguards currently include:

- `5` new lecture uploads per account per UTC day
- `5` lecture regenerations per account per UTC day

For a step-by-step instance setup checklist, see [EC2_CHECKLIST.md](./EC2_CHECKLIST.md).
`systemd` unit templates are available in [deploy/systemd](./deploy/systemd).
An Nginx reverse-proxy template is available in [deploy/nginx](./deploy/nginx).

## Step 6: Reverse proxy and domain

Use `Nginx` in front of the API and point your domain or subdomain to the EC2 public endpoint.

Suggested split:

- `api.yourdomain.com` -> FastAPI
- Flutter app/web client points `API_BASE_URL` to that backend URL

For HTTPS, the simplest starter path is Nginx + Certbot on the EC2 instance after DNS is pointing correctly.

## Step 7: First deployment test

Verify these in order:

1. open `/health`
2. open `/ready` and confirm all components are marked ready
3. open `/docs`
4. create a user
5. upload a `PDF` or `PPTX`
6. confirm an SQS message is created
7. confirm the worker consumes the message
8. confirm the original file lands in `S3_BUCKET_RAW`
9. confirm generated audio lands in `S3_BUCKET_AUDIO`
10. confirm the lecture appears in the app

## Step 8: Cost-aware upgrades later

Move to these only after traction:

1. `RDS PostgreSQL` if you launched with SQLite on EC2
2. `CloudFront` for audio delivery
3. `ECS` or `Fargate` for separate API and worker services
4. `Step Functions` for multi-stage orchestration and richer progress tracking
5. `Secrets Manager` or Parameter Store for secret management

If you are planning the SQLite -> PostgreSQL cutover, see [POSTGRESQL_MIGRATION.md](./POSTGRESQL_MIGRATION.md).

## Current Queue Modes

The backend now supports:

- `QUEUE_PROVIDER=celery`
- `QUEUE_PROVIDER=sqs`
- `QUEUE_PROVIDER=sync`

Recommended usage:

- local development with existing worker setup: `celery`
- local debugging without queue infra: `sync`
- AWS launch path: `sqs`
