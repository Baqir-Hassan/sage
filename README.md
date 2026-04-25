# Sage

Sage is a final year project that turns study material into spoken lectures. Users can upload `PDF` and `PPTX` notes, choose a narration voice, and generate audio lecture sections that can be played back inside the Flutter app.

## Live Links

- Web app: [https://sageai.live](https://sageai.live)
- API base: [https://api.sageai.live](https://api.sageai.live)
- APK download: [https://sageai.live/downloads/sage-android.apk](https://sageai.live/downloads/sage-android.apk)

## What It Does

- Upload lecture notes as `PDF` or `PPTX`
- Extract and structure the note content on the backend
- Generate lecture-style narration text
- Convert lecture sections into audio
- Organize output by subject
- Browse recent lectures, saved lectures, uploads, and subject libraries

## Project Structure

This repository contains two main parts:

- `lib/`: Flutter frontend
- `backend/`: FastAPI backend, processing pipeline, worker, and storage support

## Tech Stack

### Frontend

- Flutter
- Dart
- BLoC / Cubit state management
- `just_audio`
- `audio_service` (Android lock screen / notification controls)
- `flutter_svg`
- Web build support (runs in Chrome, deployable to Netlify)
- Web-only APK download button (Get Started + Home app bar)

### Backend

- FastAPI
- SQLAlchemy
- SQLite for local development
- AWS S3-ready storage configuration
- PyMuPDF for PDF parsing
- `python-pptx` for PowerPoint parsing
- `edge-tts` for audio generation
- Groq for lecture/script generation
- Background processing via an SQS worker (managed as a systemd service in production)

## Current Flow

1. Sign in from the Flutter app
2. Upload a `PDF` or `PPTX`
3. Choose a voice option
4. Select an existing subject or enter a new subject name
5. Backend stores the upload and queues processing with the worker
6. User polls processing status from the app
7. Generated lecture sections become playable as audio

## Supported File Types

- `PDF`
- `PPTX`

Legacy `.ppt` files are not supported.

## Production Notes (Current Deployment)

- **Backend**: runs on an EC2 instance, managed with `systemd` services.
- **Database**: SQLite (current deployment).
- **Frontend**: Flutter app (Android) and Flutter web build on Netlify.
- **Domains**:
  - `sageai.live` -> Netlify (web)
  - `api.sageai.live` -> EC2 backend API

## Local Development

### 1. Backend setup

From the project root:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Update `.env` with your own values, especially:

- `SECRET_KEY`
- `GROQ_API_KEY`
- optional AWS S3 settings if you are not using local storage

### 2. Start the worker (development)

Open a new terminal from the project root:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m app.workers.sqs_worker
```

### 3. Start the FastAPI server

Open another terminal from the project root:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload
```

Backend docs:

- Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### 4. Run the Flutter app

From the project root:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

`API_BASE_URL` is configurable at build/run time. For production builds it defaults to `https://api.sageai.live` (see `lib/core/constants/api_urls.dart`).

### 5. Build and run Flutter web (portfolio)

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.sageai.live
flutter run -d chrome --dart-define=API_BASE_URL=https://api.sageai.live
```

For Netlify deployment, publish the generated `build/web` directory.

### 6. Netlify/domain notes

- Web tab title and manifest name are set to **Sage**.
- Web favicon points to the app logo asset.
- APK download button is shown on web only and links to:
  - `https://sageai.live/downloads/sage-android.apk`
- Keep backend CORS origins aligned with deployed frontend domains:
  - `https://sageai.live`
  - `https://www.sageai.live`
  - optional Netlify preview domain(s)

## Environment Notes

Important backend environment variables:

- `DATABASE_URL`
- `STORAGE_PROVIDER`
- `LOCAL_STORAGE_PATH`
- `GROQ_API_KEY`
- `DEFAULT_MALE_VOICE`
- `DEFAULT_FEMALE_VOICE`

Local development currently works with:

- SQLite database
- local file storage in `backend/storage`

## Main API Areas

- `/api/v1/auth`
- `/api/v1/uploads`
- `/api/v1/lectures`
- `/api/v1/library/home`
- `/api/v1/subjects`
- `/api/v1/playlists`

## Notes

- Upload processing depends on the worker being available.
- For production deployment, the backend is already structured to move from local storage to S3-backed storage.

## Future Improvements

- Add step-based processing progress for uploads
- Improve lecture artwork and branding
- Expand backend test coverage
- Add deployment automation for EC2 (push-to-deploy)