from sqlalchemy import ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class Subject(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "subjects"

    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_subject_user_name"),
        UniqueConstraint("user_id", "slug", name="uq_subject_user_slug"),
    )

    name: Mapped[str] = mapped_column(String(120), index=True)
    slug: Mapped[str] = mapped_column(String(140), index=True)
    description: Mapped[str | None] = mapped_column(Text(), nullable=True)
    cover_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)

    user = relationship("User", back_populates="subjects")
    playlists = relationship("Playlist", back_populates="subject")
    documents = relationship("Document", back_populates="subject")