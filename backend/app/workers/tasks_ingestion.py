import json

from celery.utils.log import get_task_logger

from app.workers.celery_app import celery_app
from app.services.queue_service import QueueMessage
from app.workers.document_processing import process_queue_message


logger = get_task_logger(__name__)


@celery_app.task(name="app.workers.tasks_ingestion.enqueue_document_processing")
def enqueue_document_processing(message_json: str) -> None:
    logger.info("Queued background job payload=%s", message_json)
    payload = json.loads(message_json)
    process_queue_message(
        QueueMessage(
            message_type=payload.get("message_type", ""),
            document_id=payload.get("document_id"),
            lecture_id=payload.get("lecture_id"),
            processing_job_id=payload.get("processing_job_id"),
        )
    )
