import logging
from dataclasses import asdict

from app.db.session import SessionLocal
from app.models.lecture import Lecture
from app.models.processing_job import ProcessingJob
from app.services.processing_service import ProcessingService
from app.services.queue_service import QueueMessage


logger = logging.getLogger(__name__)


def process_document_job(document_id: str) -> None:
    logger.info("Starting document processing for document_id=%s", document_id)
    db = SessionLocal()
    try:
        ProcessingService(db).process_document(document_id)
        logger.info("Completed document processing for document_id=%s", document_id)
    finally:
        db.close()


def process_queue_message(message: QueueMessage) -> None:
    logger.info("Processing queued message: %s", asdict(message))
    if message.message_type == "document_processing":
        if not message.document_id:
            raise ValueError("document_processing requires document_id.")
        process_document_job(message.document_id)
        return

    if message.message_type == "lecture_audio_generation":
        if not message.lecture_id:
            raise ValueError("lecture_audio_generation requires lecture_id.")
        _process_lecture_audio_job(message.lecture_id, message.processing_job_id)
        return

    if message.message_type == "lecture_content_regeneration":
        if not message.lecture_id:
            raise ValueError("lecture_content_regeneration requires lecture_id.")
        _process_lecture_regeneration_job(message.lecture_id, message.processing_job_id)
        return

    raise ValueError(f"Unsupported queue message type: {message.message_type}")


def _process_lecture_audio_job(lecture_id: str, processing_job_id: str | None) -> None:
    db = SessionLocal()
    try:
        job = db.get(ProcessingJob, processing_job_id) if processing_job_id else None
        if job:
            job.status = "processing"
            db.commit()

        ProcessingService(db).generate_audio_for_lecture(lecture_id)

        if job:
            job.status = "completed"
            job.error_message = None
            db.commit()
    except Exception as exc:
        lecture = db.get(Lecture, lecture_id)
        if lecture:
            lecture.status = "failed"
        if processing_job_id:
            job = db.get(ProcessingJob, processing_job_id)
            if job:
                job.status = "failed"
                job.error_message = str(exc)
        db.commit()
        raise
    finally:
        db.close()


def _process_lecture_regeneration_job(lecture_id: str, processing_job_id: str | None) -> None:
    db = SessionLocal()
    try:
        job = db.get(ProcessingJob, processing_job_id) if processing_job_id else None
        if job:
            job.status = "processing"
            db.commit()

        ProcessingService(db).regenerate_lecture_content(lecture_id)

        if job:
            job.status = "completed"
            job.error_message = None
            db.commit()
    except Exception as exc:
        lecture = db.get(Lecture, lecture_id)
        if lecture:
            lecture.status = "failed"
        if processing_job_id:
            job = db.get(ProcessingJob, processing_job_id)
            if job:
                job.status = "failed"
                job.error_message = str(exc)
        db.commit()
        raise
    finally:
        db.close()
