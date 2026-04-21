from typing import Literal

from pydantic import BaseModel, ConfigDict


class LectureResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    document_id: str
    owner_user_id: str
    primary_playlist_id: str | None = None
    title: str
    description: str | None = None
    voice_option: str
    tts_voice_code: str | None = None
    status: str


class VoiceUpdateRequest(BaseModel):
    voice_option: Literal["male", "female"]
    tts_voice_code: str | None = None


class LectureTrackResponse(BaseModel):
    id: str
    section_id: str
    title: str
    order_index: int
    duration_seconds: int | None = None
    status: str
    media_url: str | None = None
