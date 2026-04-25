from pathlib import Path
import re
from urllib.parse import urlparse
from uuid import uuid4

import boto3

from app.core.config import get_settings


_SAFE_FILENAME_RE = re.compile(r"[^A-Za-z0-9._-]+")


def _sanitize_filename(filename: str) -> str:
    raw_name = Path(filename).name
    sanitized = _SAFE_FILENAME_RE.sub("_", raw_name).strip("._")
    return sanitized or "upload.bin"


class LocalStorageService:
    def __init__(self) -> None:
        settings = get_settings()
        self.base_path = settings.local_storage_dir

    def save_upload(self, filename: str, content: bytes) -> str:
        uploads_dir = self.base_path / "uploads"
        uploads_dir.mkdir(parents=True, exist_ok=True)
        safe_name = _sanitize_filename(filename)
        storage_path = uploads_dir / f"{uuid4()}-{safe_name}"
        storage_path.write_bytes(content)
        return str(storage_path)

    def resolve_storage_path(self, storage_key: str) -> Path:
        candidate = Path(storage_key)
        if candidate.exists():
            return candidate

        normalized_parts = [part.lower() for part in candidate.parts]
        if "storage" in normalized_parts:
            storage_index = normalized_parts.index("storage")
            relative_parts = candidate.parts[storage_index + 1 :]
            repaired = self.base_path.joinpath(*relative_parts)
            if repaired.exists():
                return repaired

        repaired_by_name = self.base_path / candidate.name
        if repaired_by_name.exists():
            return repaired_by_name

        raise FileNotFoundError(f"Stored file not found: {storage_key}")

    def build_audio_path(self, lecture_id: str, section_id: str) -> Path:
        audio_dir = self.base_path / "audio" / lecture_id
        audio_dir.mkdir(parents=True, exist_ok=True)
        return audio_dir / f"{section_id}.mp3"

    def persist_generated_audio(self, output_path: Path, lecture_id: str, section_id: str) -> str:
        return str(output_path)

    def read_bytes(self, storage_key: str) -> bytes:
        return self.resolve_storage_path(storage_key).read_bytes()

    def delete(self, storage_key: str) -> None:
        try:
            storage_path = self.resolve_storage_path(storage_key)
        except FileNotFoundError:
            return
        if storage_path.exists():
            storage_path.unlink()

    def to_media_url(self, storage_key: str) -> str:
        storage_path = self.resolve_storage_path(storage_key).resolve()
        relative_path = storage_path.relative_to(self.base_path)
        return f"/media/{relative_path.as_posix()}"

    def check_connection(self) -> dict[str, object]:
        try:
            self.base_path.mkdir(parents=True, exist_ok=True)
            probe_dir = self.base_path / "healthcheck"
            probe_dir.mkdir(parents=True, exist_ok=True)
            probe_file = probe_dir / ".write_test"
            probe_file.write_text("ok", encoding="utf-8")
            probe_file.unlink(missing_ok=True)
            return {
                "provider": "local",
                "ready": True,
                "base_path": str(self.base_path),
            }
        except Exception as exc:
            return {
                "provider": "local",
                "ready": False,
                "base_path": str(self.base_path),
                "detail": str(exc),
            }


class S3StorageService:
    def __init__(self) -> None:
        self.settings = get_settings()
        self.base_path = self.settings.local_storage_dir
        self.base_path.mkdir(parents=True, exist_ok=True)
        client_kwargs: dict[str, str] = {"region_name": self.settings.aws_region}
        if self.settings.aws_s3_endpoint_url:
            client_kwargs["endpoint_url"] = self.settings.aws_s3_endpoint_url
        self.client = boto3.client("s3", **client_kwargs)

    def save_upload(self, filename: str, content: bytes) -> str:
        safe_name = _sanitize_filename(filename)
        key = f"uploads/{uuid4()}-{safe_name}"
        self.client.put_object(
            Bucket=self.settings.s3_bucket_raw,
            Key=key,
            Body=content,
        )
        return self._build_s3_uri(self.settings.s3_bucket_raw, key)

    def resolve_storage_path(self, storage_key: str) -> Path:
        candidate = Path(storage_key)
        if candidate.exists():
            return candidate

        bucket, key = self._parse_s3_uri(storage_key)
        normalized_key = key.replace("\\", "/").strip("/")
        key_path = Path(normalized_key)
        if any(part in {"", ".", ".."} for part in key_path.parts):
            raise ValueError(f"Unsafe S3 storage key path: {storage_key}")

        tmp_root = (self.base_path / "tmp" / bucket).resolve()
        local_path = (tmp_root / key_path).resolve()
        if tmp_root != local_path and tmp_root not in local_path.parents:
            raise ValueError(f"Unsafe S3 storage key path: {storage_key}")

        local_path.parent.mkdir(parents=True, exist_ok=True)
        if not local_path.exists():
            self.client.download_file(bucket, key, str(local_path))
        return local_path

    def build_audio_path(self, lecture_id: str, section_id: str) -> Path:
        audio_dir = self.base_path / "tmp" / "audio" / lecture_id
        audio_dir.mkdir(parents=True, exist_ok=True)
        return audio_dir / f"{section_id}.mp3"

    def persist_generated_audio(self, output_path: Path, lecture_id: str, section_id: str) -> str:
        key = f"audio/{lecture_id}/{section_id}.mp3"
        with output_path.open("rb") as audio_file:
            self.client.upload_fileobj(
                audio_file,
                self.settings.s3_bucket_audio,
                key,
                ExtraArgs={"ContentType": "audio/mpeg"},
            )
        return self._build_s3_uri(self.settings.s3_bucket_audio, key)

    def read_bytes(self, storage_key: str) -> bytes:
        bucket, key = self._parse_s3_uri(storage_key)
        response = self.client.get_object(Bucket=bucket, Key=key)
        return response["Body"].read()

    def delete(self, storage_key: str) -> None:
        bucket, key = self._parse_s3_uri(storage_key)
        self.client.delete_object(Bucket=bucket, Key=key)

    def to_media_url(self, storage_key: str) -> str:
        bucket, key = self._parse_s3_uri(storage_key)
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket, "Key": key},
            ExpiresIn=self.settings.s3_presign_expiry_seconds,
        )

    def check_connection(self) -> dict[str, object]:
        bucket_status: dict[str, str] = {}
        try:
            buckets = {
                "raw": self.settings.s3_bucket_raw,
                "audio": self.settings.s3_bucket_audio,
                "artifacts": self.settings.s3_bucket_artifacts,
            }
            missing = [name for name, bucket in buckets.items() if not bucket]
            if missing:
                return {
                    "provider": "s3",
                    "ready": False,
                    "detail": f"Missing S3 bucket configuration: {', '.join(missing)}",
                }

            for name, bucket in buckets.items():
                self.client.head_bucket(Bucket=bucket)
                bucket_status[name] = bucket

            return {
                "provider": "s3",
                "ready": True,
                "buckets": bucket_status,
            }
        except Exception as exc:
            return {
                "provider": "s3",
                "ready": False,
                "buckets": bucket_status,
                "detail": str(exc),
            }

    def _build_s3_uri(self, bucket: str, key: str) -> str:
        return f"s3://{bucket}/{key}"

    def _parse_s3_uri(self, storage_key: str) -> tuple[str, str]:
        parsed = urlparse(storage_key)
        if parsed.scheme != "s3" or not parsed.netloc or not parsed.path:
            raise ValueError(f"Unsupported S3 storage key: {storage_key}")
        return parsed.netloc, parsed.path.lstrip("/")


def get_storage_service() -> LocalStorageService | S3StorageService:
    settings = get_settings()
    if settings.use_s3_storage:
        return S3StorageService()
    return LocalStorageService()
