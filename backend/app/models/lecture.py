from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class Lecture(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "lectures"

    document_id: Mapped[str] = mapped_column(ForeignKey("documents.id"), index=True)
    owner_user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    primary_playlist_id: Mapped[str | None] = mapped_column(
        ForeignKey("playlists.id"),
        nullable=True,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text(), nullable=True)
    voice_option: Mapped[str] = mapped_column(String(20), default="female")
    tts_voice_code: Mapped[str | None] = mapped_column(String(120), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="draft", index=True)

    document = relationship("Document", back_populates="lectures")
    owner = relationship("User", back_populates="lectures")
    sections = relationship("LectureSection", back_populates="lecture")
    playlist_links = relationship("PlaylistLecture", back_populates="lecture")
