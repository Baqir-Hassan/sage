# Backend

Python backend for the notes-to-audio lecture app.

## Stack

- FastAPI
- SQLAlchemy
- Celery + Redis
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
4. Run the API:

```bash
uvicorn app.main:app --reload --app-dir backend
```

This works locally with:

- SQLite database
- local file storage in `backend/storage`
- FastAPI background tasks for document processing

5. Optional: run the Celery worker later when you move to Redis-backed async jobs:

```bash
celery -A app.workers.celery_app.celery_app worker --loglevel=info
```

## Initial scope

- Auth skeleton
- Subjects and playlists
- Lecture and section models
- Processing job tracking
- Upload endpoint with local file persistence
- Local background processing
- Library home endpoint
- Celery task wiring

## Current API flow

1. `POST /api/v1/auth/signup`
2. `POST /api/v1/auth/login`
3. Use the Swagger `Authorize` button or send `Authorization: Bearer <token>` on protected routes
4. `POST /api/v1/uploads` with:
   - `file`
   - `voice_option` as `male` or `female`
   - optional `subject_id`
5. Poll `GET /api/v1/uploads/{document_id}/status`
6. Read `GET /api/v1/library/home`, `GET /api/v1/lectures`, and `GET /api/v1/playlists`
7. Fetch `GET /api/v1/lectures/{lecture_id}/tracks` for generated section audio URLs

Swagger auth uses `POST /api/v1/auth/token` with your email in the `username` field.
