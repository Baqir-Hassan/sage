from sqlalchemy import ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class PlaylistLecture(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "playlist_lectures"
    __table_args__ = (UniqueConstraint("playlist_id", "lecture_id", name="uq_playlist_lecture"),)

    playlist_id: Mapped[str] = mapped_column(ForeignKey("playlists.id"), index=True)
    lecture_id: Mapped[str] = mapped_column(ForeignKey("lectures.id"), index=True)
    position: Mapped[int] = mapped_column(Integer, default=0)

    playlist = relationship("Playlist", back_populates="playlist_lectures")
    lecture = relationship("Lecture", back_populates="playlist_links")
