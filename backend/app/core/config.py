from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = Field(default="Notes to Lecture API", alias="APP_NAME")
    app_env: str = Field(default="development", alias="APP_ENV")
    debug: bool = Field(default=True, alias="DEBUG")
    api_v1_prefix: str = Field(default="/api/v1", alias="API_V1_PREFIX")

    secret_key: str = Field(alias="SECRET_KEY")
    access_token_expire_minutes: int = Field(default=1440, alias="ACCESS_TOKEN_EXPIRE_MINUTES")

    database_url: str = Field(default="sqlite:///./app.db", alias="DATABASE_URL")
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")
    frontend_origins: str = Field(
        default="http://localhost:3000,http://localhost:8080,http://localhost:5173",
        alias="FRONTEND_ORIGINS",
    )
    frontend_origin_regex: str = Field(
        default=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        alias="FRONTEND_ORIGIN_REGEX",
    )
    local_storage_path: str = Field(default="./storage", alias="LOCAL_STORAGE_PATH")

    aws_region: str = Field(default="us-east-1", alias="AWS_REGION")
    s3_bucket_raw: str = Field(default="", alias="S3_BUCKET_RAW")
    s3_bucket_audio: str = Field(default="", alias="S3_BUCKET_AUDIO")
    s3_bucket_artifacts: str = Field(default="", alias="S3_BUCKET_ARTIFACTS")

    groq_api_key: str = Field(default="", alias="GROQ_API_KEY")
    groq_model: str = Field(default="llama-3.3-70b-versatile", alias="GROQ_MODEL")

    default_male_voice: str = Field(default="en-US-AndrewNeural", alias="DEFAULT_MALE_VOICE")
    default_female_voice: str = Field(default="en-US-JennyNeural", alias="DEFAULT_FEMALE_VOICE")

    @property
    def frontend_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.frontend_origins.split(",") if origin.strip()]

    @property
    def local_storage_dir(self) -> Path:
        return Path(self.local_storage_path).resolve()


@lru_cache
def get_settings() -> Settings:
    return Settings()
