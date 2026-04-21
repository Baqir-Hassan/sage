from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.lecture import Lecture
from app.models.playlist import Playlist
from app.models.user import User
from app.schemas.library import HomeLectureItem, HomePlaylistItem, LibraryHomeResponse


router = APIRouter()


@router.get("/home", response_model=LibraryHomeResponse)
def get_library_home(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> LibraryHomeResponse:
    lectures = db.scalars(
        select(Lecture)
        .where(Lecture.owner_user_id == current_user.id)
        .order_by(Lecture.created_at.desc())
        .limit(12)
    ).all()
    playlists = db.scalars(
        select(Playlist)
        .where((Playlist.user_id.is_(None)) | (Playlist.user_id == current_user.id))
        .order_by(Playlist.created_at.desc())
        .limit(12)
    ).all()
    return LibraryHomeResponse(
        recent_lectures=[HomeLectureItem.model_validate(lecture) for lecture in lectures],
        playlists=[HomePlaylistItem.model_validate(playlist) for playlist in playlists],
    )
