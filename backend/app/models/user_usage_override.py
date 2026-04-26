from sqlalchemy import ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class UserUsageOverride(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "user_usage_overrides"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    daily_new_lecture_limit: Mapped[int | None] = mapped_column(Integer, nullable=True)
    daily_regeneration_limit: Mapped[int | None] = mapped_column(Integer, nullable=True)

    user = relationship("User", back_populates="usage_override")
