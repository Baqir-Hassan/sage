from pydantic import BaseModel, ConfigDict


class HomeLectureItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    voice_option: str
    status: str


class HomePlaylistItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    playlist_type: str


class LibraryHomeResponse(BaseModel):
    recent_lectures: list[HomeLectureItem]
    playlists: list[HomePlaylistItem]
