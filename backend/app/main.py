from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.db.base import Base
from app.db.session import engine
from app.models import (  # noqa: F401
    AudioTrack,
    Document,
    Lecture,
    LectureSection,
    Playlist,
    PlaylistLecture,
    ProcessingJob,
    Subject,
    User,
)
from app.services.readiness_service import collect_readiness_status


settings = get_settings()
configured_origins = [origin for origin in settings.frontend_origin_list if origin != "*"]

if settings.app_env != "development" and not configured_origins:
    raise RuntimeError("FRONTEND_ORIGINS must be explicitly configured outside development.")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings.local_storage_dir.mkdir(parents=True, exist_ok=True)
    if settings.app_env == "development":
        Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=configured_origins if configured_origins else settings.frontend_origin_list,
    allow_origin_regex=settings.frontend_origin_regex if not configured_origins else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.api_v1_prefix)
if not settings.use_s3_storage:
    app.mount("/media", StaticFiles(directory=settings.local_storage_dir), name="media")


@app.get("/health", tags=["health"])
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "environment": settings.app_env}


@app.get("/ready", tags=["health"])
def readiness_check():
    readiness = collect_readiness_status()
    status_code = 200 if readiness["status"] == "ready" else 503
    return JSONResponse(status_code=status_code, content=readiness)
