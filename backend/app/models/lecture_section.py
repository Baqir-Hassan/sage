from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class LectureSection(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "lecture_sections"

    lecture_id: Mapped[str] = mapped_column(ForeignKey("lectures.id"), index=True)
    title: Mapped[str] = mapped_column(String(255))
    script_text: Mapped[str] = mapped_column(Text())
    order_index: Mapped[int] = mapped_column(Integer)
    estimated_duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)

    lecture = relationship("Lecture", back_populates="sections")
    audio_track = relationship("AudioTrack", back_populates="section", uselist=False)
