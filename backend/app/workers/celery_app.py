from celery import Celery

from app.core.config import get_settings


settings = get_settings()

celery_app = Celery(
    "notes_audio",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

celery_app.conf.task_routes = {
    "app.workers.tasks_ingestion.*": {"queue": "ingestion"},
}
