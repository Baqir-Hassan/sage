from __future__ import annotations

import json
from dataclasses import dataclass

import boto3
import redis

from app.core.config import get_settings


@dataclass(frozen=True)
class QueueMessage:
    message_type: str
    document_id: str | None = None
    lecture_id: str | None = None
    processing_job_id: str | None = None

    def to_json(self) -> str:
        return json.dumps(
            {
                "message_type": self.message_type,
                "document_id": self.document_id,
                "lecture_id": self.lecture_id,
                "processing_job_id": self.processing_job_id,
            }
        )


class QueueService:
    def enqueue_document_processing(self, document_id: str) -> None:
        raise NotImplementedError

    def enqueue_lecture_audio_generation(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        raise NotImplementedError

    def enqueue_lecture_regeneration(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        raise NotImplementedError

    def check_connection(self) -> dict[str, object]:
        raise NotImplementedError


class CeleryQueueService(QueueService):
    def enqueue_document_processing(self, document_id: str) -> None:
        self._dispatch(
            QueueMessage(
                message_type="document_processing",
                document_id=document_id,
            )
        )

    def enqueue_lecture_audio_generation(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        self._dispatch(
            QueueMessage(
                message_type="lecture_audio_generation",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def enqueue_lecture_regeneration(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        self._dispatch(
            QueueMessage(
                message_type="lecture_content_regeneration",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def _dispatch(self, message: QueueMessage) -> None:
        from app.workers.tasks_ingestion import enqueue_document_processing

        enqueue_document_processing.delay(message.to_json())

    def check_connection(self) -> dict[str, object]:
        settings = get_settings()
        try:
            redis.from_url(settings.redis_url).ping()
            return {"provider": "celery", "ready": True}
        except Exception as exc:
            return {"provider": "celery", "ready": False, "detail": str(exc)}


class SqsQueueService(QueueService):
    def __init__(self) -> None:
        settings = get_settings()
        region_name = settings.sqs_region or settings.aws_region
        self.queue_url = settings.sqs_queue_url
        self.client = boto3.client("sqs", region_name=region_name)

    def enqueue_document_processing(self, document_id: str) -> None:
        self._send(
            QueueMessage(
                message_type="document_processing",
                document_id=document_id,
            )
        )

    def enqueue_lecture_audio_generation(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        self._send(
            QueueMessage(
                message_type="lecture_audio_generation",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def enqueue_lecture_regeneration(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        self._send(
            QueueMessage(
                message_type="lecture_content_regeneration",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def _send(self, message: QueueMessage) -> None:
        if not self.queue_url:
            raise RuntimeError("SQS_QUEUE_URL is required when QUEUE_PROVIDER=sqs.")

        self.client.send_message(
            QueueUrl=self.queue_url,
            MessageBody=message.to_json(),
        )

    def check_connection(self) -> dict[str, object]:
        if not self.queue_url:
            return {
                "provider": "sqs",
                "ready": False,
                "detail": "SQS_QUEUE_URL is required when QUEUE_PROVIDER=sqs.",
            }
        try:
            attributes = self.client.get_queue_attributes(
                QueueUrl=self.queue_url,
                AttributeNames=["QueueArn"],
            )
            return {
                "provider": "sqs",
                "ready": True,
                "queue_arn": attributes.get("Attributes", {}).get("QueueArn"),
            }
        except Exception as exc:
            return {"provider": "sqs", "ready": False, "detail": str(exc)}


class SyncQueueService(QueueService):
    def enqueue_document_processing(self, document_id: str) -> None:
        from app.workers.document_processing import process_queue_message

        process_queue_message(
            QueueMessage(
                message_type="document_processing",
                document_id=document_id,
            )
        )

    def enqueue_lecture_audio_generation(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        from app.workers.document_processing import process_queue_message

        process_queue_message(
            QueueMessage(
                message_type="lecture_audio_generation",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def enqueue_lecture_regeneration(
        self,
        lecture_id: str,
        processing_job_id: str | None = None,
        document_id: str | None = None,
    ) -> None:
        from app.workers.document_processing import process_queue_message

        process_queue_message(
            QueueMessage(
                message_type="lecture_content_regeneration",
                lecture_id=lecture_id,
                processing_job_id=processing_job_id,
                document_id=document_id,
            )
        )

    def check_connection(self) -> dict[str, object]:
        return {"provider": "sync", "ready": True}


def get_queue_service() -> QueueService:
    settings = get_settings()
    provider = settings.queue_provider.strip().lower()

    if provider == "celery":
        return CeleryQueueService()
    if provider == "sqs":
        return SqsQueueService()
    if provider == "sync":
        return SyncQueueService()

    raise RuntimeError(f"Unsupported queue provider: {settings.queue_provider}")
