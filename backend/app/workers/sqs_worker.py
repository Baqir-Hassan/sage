from __future__ import annotations

import json
import logging
import time

import boto3

from app.core.config import get_settings
from app.services.queue_service import QueueMessage
from app.workers.document_processing import process_queue_message


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run() -> None:
    settings = get_settings()
    queue_url = settings.sqs_queue_url
    if not queue_url:
        raise RuntimeError("SQS_QUEUE_URL is required to run the SQS worker.")

    region_name = settings.sqs_region or settings.aws_region
    client = boto3.client("sqs", region_name=region_name)

    logger.info("Starting SQS worker for queue=%s", queue_url)
    while True:
        response = client.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=max(1, min(settings.sqs_max_messages, 10)),
            WaitTimeSeconds=max(0, min(settings.sqs_wait_time_seconds, 20)),
        )
        messages = response.get("Messages", [])
        if not messages:
            time.sleep(1)
            continue

        for message in messages:
            receipt_handle = message["ReceiptHandle"]
            body = message.get("Body", "{}")

            try:
                payload = json.loads(body)
                process_queue_message(
                    QueueMessage(
                        message_type=payload.get("message_type", ""),
                        document_id=payload.get("document_id"),
                        lecture_id=payload.get("lecture_id"),
                        processing_job_id=payload.get("processing_job_id"),
                    )
                )
                client.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=receipt_handle,
                )
            except Exception:
                logger.exception("Failed to process SQS message: %s", body)


if __name__ == "__main__":
    run()
