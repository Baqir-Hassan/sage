from pydantic import BaseModel, ConfigDict


class HomeLectureItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    voice_option: str
    status: str
    total_duration_seconds: int = 0
    total_track_count: int = 0
    ready_track_count: int = 0
    primary_audio_url: str | None = None


class HomePlaylistItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    playlist_type: str


class LibraryHomeResponse(BaseModel):
    recent_lectures: list[HomeLectureItem]
    playlists: list[HomePlaylistItem]
