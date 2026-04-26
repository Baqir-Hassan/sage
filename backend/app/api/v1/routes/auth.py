from datetime import datetime, timedelta
import hashlib
import secrets
from urllib.parse import quote_plus
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.config import get_settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    OAuthTokenResponse,
    ResendVerificationRequest,
    SignupPendingVerificationResponse,
    SignupRequest,
    TokenResponse,
    UserResponse,
    VerifyEmailRequest,
)
from app.services.email_service import EmailDeliveryError, EmailService


router = APIRouter()


@router.post("/signup", response_model=SignupPendingVerificationResponse, status_code=status.HTTP_201_CREATED)
def signup(payload: SignupRequest, db: Session = Depends(get_db)) -> SignupPendingVerificationResponse:
    existing = db.scalar(select(User).where(User.email == payload.email))
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account already exists with that email.",
        )

    token, token_hash, token_expiry = _build_verification_token()
    user = User(
        id=str(uuid4()),
        full_name=payload.full_name,
        email=payload.email,
        hashed_password=get_password_hash(payload.password),
        email_verified=False,
        verification_token_hash=token_hash,
        verification_token_expires_at=token_expiry,
        verification_sent_at=datetime.utcnow(),
    )
    db.add(user)
    db.commit()
    _send_verification_email(user.email, token)
    return SignupPendingVerificationResponse(
        message=(
            "Account created. Please verify your email before signing in. "
            "If you do not see it, check your spam/junk folder."
        )
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )
    if not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Please verify your email before signing in. "
                "If you do not see the email, check your spam/junk folder."
            ),
        )

    token = create_access_token(subject=user.id)
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))


@router.post("/token", response_model=OAuthTokenResponse)
def issue_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
) -> OAuthTokenResponse:
    user = db.scalar(select(User).where(User.email == form_data.username))
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Please verify your email before signing in. "
                "If you do not see the email, check your spam/junk folder."
            ),
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(subject=user.id)
    return OAuthTokenResponse(access_token=token)


@router.post("/verify-email", status_code=status.HTTP_200_OK)
def verify_email(payload: VerifyEmailRequest, db: Session = Depends(get_db)) -> dict[str, str]:
    token_hash = _hash_verification_token(payload.token)
    user = db.scalar(select(User).where(User.verification_token_hash == token_hash))
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired verification token.")

    now = datetime.utcnow()
    if not user.verification_token_expires_at or user.verification_token_expires_at < now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired verification token.")

    user.email_verified = True
    user.verification_token_hash = None
    user.verification_token_expires_at = None
    user.verification_sent_at = None
    db.add(user)
    db.commit()
    return {"message": "Email verified successfully. You can now sign in."}


@router.post("/resend-verification", status_code=status.HTTP_200_OK)
def resend_verification(payload: ResendVerificationRequest, db: Session = Depends(get_db)) -> dict[str, str]:
    generic_message = (
        "If an unverified account exists for this email, we sent a verification link. "
        "If you do not see it, check your spam/junk folder."
    )
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user or user.email_verified:
        return {"message": generic_message}

    now = datetime.utcnow()
    settings = get_settings()
    if user.verification_sent_at:
        next_allowed = user.verification_sent_at + timedelta(seconds=settings.verification_resend_cooldown_seconds)
        if next_allowed > now:
            retry_seconds = int((next_allowed - now).total_seconds())
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Please wait {retry_seconds}s before requesting another verification email.",
            )

    token, token_hash, token_expiry = _build_verification_token()
    user.verification_token_hash = token_hash
    user.verification_token_expires_at = token_expiry
    user.verification_sent_at = now
    db.add(user)
    db.commit()

    _send_verification_email(user.email, token)
    return {"message": generic_message}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(current_user)


def _build_verification_token() -> tuple[str, str, datetime]:
    settings = get_settings()
    token = secrets.token_urlsafe(32)
    token_hash = _hash_verification_token(token)
    token_expiry = datetime.utcnow() + timedelta(minutes=settings.verification_token_expire_minutes)
    return token, token_hash, token_expiry


def _hash_verification_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _send_verification_email(email: str, token: str) -> None:
    settings = get_settings()
    verification_url = f"{settings.verify_email_page_url}?token={quote_plus(token)}"
    try:
        EmailService().send_verification_email(to_email=email, verification_url=verification_url)
    except EmailDeliveryError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to send verification email at the moment. Please try again later.",
        ) from exc
