from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")
    reset_password_page_url: str = Field(default="https://sageai.live/reset-password", alias="RESET_PASSWORD_PAGE_URL")
    app_name: str = Field(default="Notes to Lecture API", alias="APP_NAME")
    app_env: str = Field(default="development", alias="APP_ENV")
    debug: bool = Field(default=True, alias="DEBUG")
    api_v1_prefix: str = Field(default="/api/v1", alias="API_V1_PREFIX")

    secret_key: str = Field(alias="SECRET_KEY")
    access_token_expire_minutes: int = Field(default=1440, alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    verification_token_expire_minutes: int = Field(default=60, alias="VERIFICATION_TOKEN_EXPIRE_MINUTES")
    verification_resend_cooldown_seconds: int = Field(default=60, alias="VERIFICATION_RESEND_COOLDOWN_SECONDS")

    database_url: str = Field(default="sqlite:///./app.db", alias="DATABASE_URL")
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")
    queue_provider: str = Field(default="celery", alias="QUEUE_PROVIDER")
    sqs_queue_url: str = Field(default="", alias="SQS_QUEUE_URL")
    sqs_region: str = Field(default="", alias="SQS_REGION")
    sqs_wait_time_seconds: int = Field(default=20, alias="SQS_WAIT_TIME_SECONDS")
    sqs_max_messages: int = Field(default=1, alias="SQS_MAX_MESSAGES")
    storage_provider: str = Field(default="local", alias="STORAGE_PROVIDER")
    frontend_origins: str = Field(
        default="http://localhost:3000,http://localhost:8080,http://localhost:5173",
        alias="FRONTEND_ORIGINS",
    )
    frontend_origin_regex: str = Field(
        default=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        alias="FRONTEND_ORIGIN_REGEX",
    )
    max_upload_size_mb: int = Field(default=50, alias="MAX_UPLOAD_SIZE_MB")
    local_storage_path: str = Field(default="./storage", alias="LOCAL_STORAGE_PATH")

    aws_region: str = Field(default="us-east-1", alias="AWS_REGION")
    aws_s3_endpoint_url: str = Field(default="", alias="AWS_S3_ENDPOINT_URL")
    s3_bucket_raw: str = Field(default="", alias="S3_BUCKET_RAW")
    s3_bucket_audio: str = Field(default="", alias="S3_BUCKET_AUDIO")
    s3_bucket_artifacts: str = Field(default="", alias="S3_BUCKET_ARTIFACTS")
    s3_presign_expiry_seconds: int = Field(default=3600, alias="S3_PRESIGN_EXPIRY_SECONDS")

    groq_api_key: str = Field(default="", alias="GROQ_API_KEY")
    groq_model: str = Field(default="llama-3.3-70b-versatile", alias="GROQ_MODEL")

    default_male_voice: str = Field(default="en-US-AndrewNeural", alias="DEFAULT_MALE_VOICE")
    default_female_voice: str = Field(default="en-US-JennyNeural", alias="DEFAULT_FEMALE_VOICE")
    smtp_host: str = Field(default="", alias="SMTP_HOST")
    smtp_port: int = Field(default=587, alias="SMTP_PORT")
    smtp_username: str = Field(default="", alias="SMTP_USERNAME")
    smtp_password: str = Field(default="", alias="SMTP_PASSWORD")
    smtp_from_email: str = Field(default="", alias="SMTP_FROM_EMAIL")
    verify_email_page_url: str = Field(default="https://sageai.live/verify-email", alias="VERIFY_EMAIL_PAGE_URL")

    @property
    def frontend_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.frontend_origins.split(",") if origin.strip()]

    @property
    def local_storage_dir(self) -> Path:
        return Path(self.local_storage_path).resolve()

    @property
    def use_s3_storage(self) -> bool:
        return self.storage_provider.lower() == "s3"

    @property
    def max_upload_size_bytes(self) -> int:
        return max(self.max_upload_size_mb, 1) * 1024 * 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
