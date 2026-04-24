from __future__ import annotations

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.document import Document
from app.models.processing_job import ProcessingJob


DAILY_NEW_LECTURE_LIMIT = 5
DAILY_REGENERATION_LIMIT = 5


class UsageLimitService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def enforce_new_lecture_limit(self, user_id: str) -> None:
        count = self.get_new_lecture_count_today(user_id)
        if count >= DAILY_NEW_LECTURE_LIMIT:
            raise DailyLimitExceededError(
                detail=(
                    f"Daily lecture creation limit reached. Each account can create up to "
                    f"{DAILY_NEW_LECTURE_LIMIT} new lectures per day."
                )
            )

    def enforce_regeneration_limit(self, user_id: str) -> None:
        count = self.get_regeneration_count_today(user_id)
        if count >= DAILY_REGENERATION_LIMIT:
            raise DailyLimitExceededError(
                detail=(
                    f"Daily regeneration limit reached. Each account can request up to "
                    f"{DAILY_REGENERATION_LIMIT} lecture regenerations per day."
                )
            )

    def get_new_lecture_count_today(self, user_id: str) -> int:
        start_of_day = _utc_day_start()
        count = self.db.scalar(
            select(func.count())
            .select_from(Document)
            .where(
                Document.user_id == user_id,
                Document.created_at >= start_of_day,
            )
        )
        return int(count or 0)

    def get_regeneration_count_today(self, user_id: str) -> int:
        start_of_day = _utc_day_start()
        count = self.db.scalar(
            select(func.count())
            .select_from(ProcessingJob)
            .join(Document, Document.id == ProcessingJob.document_id)
            .where(
                Document.user_id == user_id,
                ProcessingJob.job_type == "lecture_content_regeneration",
                ProcessingJob.created_at >= start_of_day,
            )
        )
        return int(count or 0)

    def build_usage_summary(self, user_id: str) -> dict[str, int]:
        new_lectures_used = self.get_new_lecture_count_today(user_id)
        regenerations_used = self.get_regeneration_count_today(user_id)
        return {
            "daily_new_lecture_limit": DAILY_NEW_LECTURE_LIMIT,
            "new_lectures_used_today": new_lectures_used,
            "new_lectures_remaining_today": max(0, DAILY_NEW_LECTURE_LIMIT - new_lectures_used),
            "daily_regeneration_limit": DAILY_REGENERATION_LIMIT,
            "regenerations_used_today": regenerations_used,
            "regenerations_remaining_today": max(0, DAILY_REGENERATION_LIMIT - regenerations_used),
        }


class DailyLimitExceededError(Exception):
    def __init__(self, detail: str) -> None:
        super().__init__(detail)
        self.detail = detail


def _utc_day_start() -> datetime:
    now = datetime.utcnow()
    return datetime(now.year, now.month, now.day)
