from celery.utils.log import get_task_logger

from app.workers.celery_app import celery_app


logger = get_task_logger(__name__)


@celery_app.task(name="app.workers.tasks_ingestion.enqueue_document_processing")
def enqueue_document_processing(document_id: str) -> None:
    logger.info("Queued document processing for document_id=%s", document_id)
