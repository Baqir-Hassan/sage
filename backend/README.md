# Backend

Python backend for the notes-to-audio lecture app.

## Stack

- FastAPI
- SQLAlchemy
- Configurable job queue (`Celery`, `SQS`, or `sync`)
- PostgreSQL
- AWS S3
- Groq API
- edge-tts

## Quick start

1. Create a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Copy `.env.example` to `.env` and update values.
   For AWS/EC2 production setup, start from [`.env.production.example`](./.env.production.example).
4. Apply database migrations:

```bash
alembic upgrade head
```

Or use the production-style migration helper on Linux/macOS/EC2:

```bash
./scripts/run_migrations.sh
```

5. Run the API:

```bash
uvicorn app.main:app --reload --app-dir backend
```

Or use the production-style launcher on Linux/macOS/EC2:

```bash
./scripts/start_api.sh
```

This works locally with:

- SQLite database
- local file storage in `backend/storage`
- one of these queue modes:
  - `QUEUE_PROVIDER=celery` with Redis + Celery
  - `QUEUE_PROVIDER=sync` for direct in-process execution
  - `QUEUE_PROVIDER=sqs` for the AWS queue path

6. If `QUEUE_PROVIDER=celery`, run the Celery worker:

```bash
celery -A app.workers.celery_app.celery_app worker --loglevel=info
```

7. If `QUEUE_PROVIDER=sqs`, run the SQS worker:

```bash
python -m app.workers.sqs_worker
```

Or use the production-style launcher on Linux/macOS/EC2:

```bash
./scripts/start_sqs_worker.sh
```

For EC2 deployment preparation, see [EC2_CHECKLIST.md](./EC2_CHECKLIST.md).

## Initial scope

- Auth skeleton
- Subjects and playlists
- Lecture and section models
- Processing job tracking
- Upload endpoint with local file persistence
- Queue-backed document processing
- Library home endpoint
- Celery and SQS worker wiring
- Async lecture audio generation and lecture content regeneration

## Current API flow

1. `POST /api/v1/auth/signup`
2. `POST /api/v1/auth/login`
3. Use the Swagger `Authorize` button or send `Authorization: Bearer <token>` on protected routes
4. `POST /api/v1/uploads` with:
   - `file`
   - `voice_option` as `male` or `female`
   - optional `subject_id`
   - optional `subject_name`
5. Poll `GET /api/v1/uploads/{document_id}/status`
6. Read `GET /api/v1/library/home`, `GET /api/v1/lectures`, and `GET /api/v1/playlists`
7. Fetch `GET /api/v1/lectures/{lecture_id}/tracks` for generated section audio URLs
8. `POST /api/v1/lectures/{lecture_id}/generate-audio` queues lecture audio generation
9. `POST /api/v1/lectures/{lecture_id}/regenerate-content` queues lecture content regeneration

Swagger auth uses `POST /api/v1/auth/token` with your email in the `username` field.

## Health Endpoints

- `/health` for basic liveness
- `/ready` for database, queue, and storage readiness checks

`/ready` returns `503` when a required dependency such as Redis, SQS, or S3 is unavailable or misconfigured.

## Daily Usage Limits

To protect launch capacity, the backend currently enforces these per-account limits:

- up to `5` new lecture uploads accepted per UTC day
- up to `5` lecture regeneration requests per UTC day

When a limit is exceeded, the API returns `429 Too Many Requests`.

## Deployment Notes

- EC2 deployment checklist: [EC2_CHECKLIST.md](./EC2_CHECKLIST.md)
- AWS launch guide: [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)
- SQLite to PostgreSQL cutover notes: [POSTGRESQL_MIGRATION.md](./POSTGRESQL_MIGRATION.md)
- Alembic config and migrations: [alembic.ini](./alembic.ini) and [migrations](./migrations)
