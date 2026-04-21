from typing import Literal

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


PlaylistType = Literal["system", "custom"]


class Playlist(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "playlists"

    title: Mapped[str] = mapped_column(String(255), index=True)
    description: Mapped[str | None] = mapped_column(Text(), nullable=True)
    playlist_type: Mapped[str] = mapped_column(String(20), default="system", index=True)
    cover_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    subject_id: Mapped[str | None] = mapped_column(ForeignKey("subjects.id"), nullable=True, index=True)

    user = relationship("User", back_populates="playlists")
    subject = relationship("Subject", back_populates="playlists")
    playlist_lectures = relationship("PlaylistLecture", back_populates="playlist")
