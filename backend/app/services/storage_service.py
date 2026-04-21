from pathlib import Path
from uuid import uuid4

from app.core.config import get_settings


class LocalStorageService:
    def __init__(self) -> None:
        settings = get_settings()
        self.base_path = settings.local_storage_dir

    def save_upload(self, filename: str, content: bytes) -> str:
        uploads_dir = self.base_path / "uploads"
        uploads_dir.mkdir(parents=True, exist_ok=True)
        safe_name = filename.replace(" ", "_")
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

    def read_bytes(self, storage_key: str) -> bytes:
        return self.resolve_storage_path(storage_key).read_bytes()

    def to_media_url(self, storage_key: str) -> str:
        storage_path = self.resolve_storage_path(storage_key).resolve()
        relative_path = storage_path.relative_to(self.base_path)
        return f"/media/{relative_path.as_posix()}"
