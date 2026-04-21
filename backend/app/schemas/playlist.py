from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class PlaylistCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: str | None = None
    playlist_type: Literal["system", "custom"] = "custom"
    user_id: str | None = None
    subject_id: str | None = None


class PlaylistResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    playlist_type: str
    cover_image_url: str | None = None
    user_id: str | None = None
    subject_id: str | None = None
