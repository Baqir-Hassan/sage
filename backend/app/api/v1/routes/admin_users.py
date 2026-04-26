from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_admin
from app.db.session import get_db
from app.models.user import User
from app.models.user_usage_override import UserUsageOverride
from app.schemas.admin import AdminUserSearchItem, UserLimitResponse, UserLimitUpdateRequest
from app.services.usage_limit_service import (
    DAILY_NEW_LECTURE_LIMIT,
    DAILY_REGENERATION_LIMIT,
    UsageLimitService,
)


router = APIRouter()


@router.get("/users/search", response_model=list[AdminUserSearchItem])
def search_users_by_email_prefix(
    email_prefix: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> list[AdminUserSearchItem]:
    normalized_prefix = email_prefix.strip().lower()
    if len(normalized_prefix) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="email_prefix must be at least 2 characters.",
        )

    users = db.scalars(
        select(User)
        .where(User.email.ilike(f"{normalized_prefix}%"))
        .order_by(User.email.asc())
        .limit(10)
    ).all()
    return [AdminUserSearchItem(id=user.id, email=user.email) for user in users]


@router.get("/users/{user_id}/limits", response_model=UserLimitResponse)
def get_user_limits(
    user_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> UserLimitResponse:
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    override = user.usage_override
    usage_summary = UsageLimitService(db).build_usage_summary(user_id)

    return UserLimitResponse(
        user_id=user.id,
        daily_new_lecture_limit=usage_summary["daily_new_lecture_limit"],
        daily_regeneration_limit=usage_summary["daily_regeneration_limit"],
        override_daily_new_lecture_limit=(
            override.daily_new_lecture_limit if override else None
        ),
        override_daily_regeneration_limit=(
            override.daily_regeneration_limit if override else None
        ),
    )


@router.get("/users/limits/by-email", response_model=UserLimitResponse)
def get_user_limits_by_email(
    email: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> UserLimitResponse:
    user = db.scalar(select(User).where(User.email == email))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    override = user.usage_override
    usage_summary = UsageLimitService(db).build_usage_summary(user.id)

    return UserLimitResponse(
        user_id=user.id,
        daily_new_lecture_limit=usage_summary["daily_new_lecture_limit"],
        daily_regeneration_limit=usage_summary["daily_regeneration_limit"],
        override_daily_new_lecture_limit=(
            override.daily_new_lecture_limit if override else None
        ),
        override_daily_regeneration_limit=(
            override.daily_regeneration_limit if override else None
        ),
    )


@router.patch("/users/{user_id}/limits", response_model=UserLimitResponse)
def update_user_limits(
    user_id: str,
    payload: UserLimitUpdateRequest,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> UserLimitResponse:
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    if payload.daily_new_lecture_limit is None and payload.daily_regeneration_limit is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide at least one limit value.",
        )

    override = user.usage_override
    if not override:
        override = UserUsageOverride(id=str(uuid4()), user_id=user.id)
        db.add(override)

    override.daily_new_lecture_limit = payload.daily_new_lecture_limit
    override.daily_regeneration_limit = payload.daily_regeneration_limit

    if (
        override.daily_new_lecture_limit is None
        and override.daily_regeneration_limit is None
    ):
        db.delete(override)

    db.commit()
    db.refresh(user)

    usage_summary = UsageLimitService(db).build_usage_summary(user_id)
    updated_override = user.usage_override
    return UserLimitResponse(
        user_id=user.id,
        daily_new_lecture_limit=usage_summary["daily_new_lecture_limit"],
        daily_regeneration_limit=usage_summary["daily_regeneration_limit"],
        override_daily_new_lecture_limit=(
            updated_override.daily_new_lecture_limit if updated_override else None
        ),
        override_daily_regeneration_limit=(
            updated_override.daily_regeneration_limit if updated_override else None
        ),
    )
