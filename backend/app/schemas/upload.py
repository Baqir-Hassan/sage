from enum import Enum

from pydantic import BaseModel


class VoiceOption(str, Enum):
    male = "male"
    female = "female"


class UploadResponse(BaseModel):
    document_id: str
    processing_job_id: str
    status: str


class UploadStatusResponse(BaseModel):
    document_id: str
    document_status: str
    processing_job_id: str
    processing_status: str
    selected_voice: str
    lecture_id: str | None = None


class UploadListItemResponse(BaseModel):
    document_id: str
    original_filename: str
    content_type: str
    document_status: str
    selected_voice: str
    lecture_id: str | None = None


class UploadLimitsResponse(BaseModel):
    daily_new_lecture_limit: int
    new_lectures_used_today: int
    new_lectures_remaining_today: int
    daily_regeneration_limit: int
    regenerations_used_today: int
    regenerations_remaining_today: int
