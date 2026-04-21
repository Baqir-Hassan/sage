from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class AudioTrack(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "audio_tracks"

    lecture_section_id: Mapped[str] = mapped_column(ForeignKey("lecture_sections.id"), unique=True)
    storage_key: Mapped[str | None] = mapped_column(String(500), nullable=True)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="pending", index=True)

    section = relationship("LectureSection", back_populates="audio_track")
