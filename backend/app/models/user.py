from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "users"

    full_name: Mapped[str] = mapped_column(String(255))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    subjects = relationship("Subject", back_populates="user")
    playlists = relationship("Playlist", back_populates="user")
    documents = relationship("Document", back_populates="user")
    lectures = relationship("Lecture", back_populates="owner")
    usage_override = relationship("UserUsageOverride", back_populates="user", uselist=False)
