from __future__ import annotations

import smtplib
from email.message import EmailMessage

from app.core.config import get_settings


class EmailDeliveryError(Exception):
    pass


class EmailService:
    def __init__(self) -> None:
        self.settings = get_settings()

    def send_verification_email(self, *, to_email: str, verification_url: str) -> None:
        if (
            not self.settings.smtp_host
            or not self.settings.smtp_username
            or not self.settings.smtp_password
            or not self.settings.smtp_from_email
        ):
            raise EmailDeliveryError("SMTP settings are not configured.")

        message = EmailMessage()
        message["Subject"] = "Verify your Sage account"
        message["From"] = self.settings.smtp_from_email
        message["To"] = to_email
        message.set_content(
            "\n".join(
                [
                    "Welcome to Sage.",
                    "",
                    "Please verify your email address by opening this link:",
                    verification_url,
                    "",
                    "If you do not see this email in your inbox, check your spam/junk folder.",
                ]
            )
        )

        try:
            with smtplib.SMTP(self.settings.smtp_host, self.settings.smtp_port, timeout=30) as smtp:
                smtp.starttls()
                smtp.login(self.settings.smtp_username, self.settings.smtp_password)
                smtp.send_message(message)
        except Exception as exc:  # pragma: no cover - network failures are environment dependent
            raise EmailDeliveryError("Unable to deliver verification email.") from exc
    def send_password_reset_email(self, *, to_email: str, reset_url: str) -> None:
        if (
            not self.settings.smtp_host
            or not self.settings.smtp_username
            or not self.settings.smtp_password
            or not self.settings.smtp_from_email
        ):
            raise EmailDeliveryError("SMTP settings are not configured.")

        message = EmailMessage()
        message["Subject"] = "Reset your Sage password"
        message["From"] = self.settings.smtp_from_email
        message["To"] = to_email
        message.set_content(
            "\n".join(
                [
                    "You requested a password reset for your Sage account.",
                    "",
                    "Click the link below to reset your password:",
                    reset_url,
                    "",
                    "This link will expire in 60 minutes.",
                    "",
                    "If you did not request this, you can safely ignore this email.",
                ]
            )
        )
        try:
            with smtplib.SMTP(self.settings.smtp_host, self.settings.smtp_port, timeout=30) as smtp:
                smtp.starttls()
                smtp.login(self.settings.smtp_username, self.settings.smtp_password)
                smtp.send_message(message)
        except Exception as exc:
            raise EmailDeliveryError("Unable to deliver password reset email.") from exc
