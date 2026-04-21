from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class Document(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "documents"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    subject_id: Mapped[str | None] = mapped_column(ForeignKey("subjects.id"), nullable=True, index=True)
    original_filename: Mapped[str] = mapped_column(String(255))
    content_type: Mapped[str] = mapped_column(String(120))
    storage_key: Mapped[str] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(50), default="uploaded", index=True)
    selected_voice: Mapped[str] = mapped_column(String(20), default="female")

    user = relationship("User", back_populates="documents")
    subject = relationship("Subject", back_populates="documents")
    processing_jobs = relationship("ProcessingJob", back_populates="document")
    lectures = relationship("Lecture", back_populates="document")
