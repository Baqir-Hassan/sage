from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.audio_track import AudioTrack
from app.models.lecture_section import LectureSection
from app.services.storage_service import get_storage_service


def build_lecture_summary_map(db: Session, lecture_ids: list[str]) -> dict[str, dict[str, int | str | None]]:
    if not lecture_ids:
        return {}

    storage = get_storage_service()
    rows = db.execute(
        select(
            LectureSection.lecture_id,
            LectureSection.order_index,
            LectureSection.estimated_duration_seconds,
            AudioTrack.duration_seconds,
            AudioTrack.status,
            AudioTrack.storage_key,
        )
        .outerjoin(AudioTrack, AudioTrack.lecture_section_id == LectureSection.id)
        .where(LectureSection.lecture_id.in_(lecture_ids))
        .order_by(LectureSection.lecture_id.asc(), LectureSection.order_index.asc())
    ).all()

    summaries: dict[str, dict[str, int | str | None]] = defaultdict(
        lambda: {
            "total_duration_seconds": 0,
            "total_track_count": 0,
            "ready_track_count": 0,
            "primary_audio_url": None,
        }
    )

    for lecture_id, _, estimated_duration, track_duration, track_status, storage_key in rows:
        summary = summaries[lecture_id]
        summary["total_track_count"] = int(summary["total_track_count"]) + 1
        summary["total_duration_seconds"] = int(summary["total_duration_seconds"]) + int(
            track_duration or estimated_duration or 0
        )

        if track_status == "ready":
            summary["ready_track_count"] = int(summary["ready_track_count"]) + 1
            if summary["primary_audio_url"] is None and storage_key:
                summary["primary_audio_url"] = storage.to_media_url(storage_key)

    return dict(summaries)
