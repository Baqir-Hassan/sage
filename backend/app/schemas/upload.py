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
