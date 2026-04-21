from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.playlist import Playlist
from app.models.user import User
from app.schemas.playlist import PlaylistCreateRequest, PlaylistResponse


router = APIRouter()


@router.get("", response_model=list[PlaylistResponse])
def list_playlists(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[PlaylistResponse]:
    playlists = db.scalars(
        select(Playlist)
        .where((Playlist.user_id.is_(None)) | (Playlist.user_id == current_user.id))
        .order_by(Playlist.created_at.desc())
    ).all()
    return [PlaylistResponse.model_validate(playlist) for playlist in playlists]


@router.post("", response_model=PlaylistResponse, status_code=status.HTTP_201_CREATED)
def create_playlist(
    payload: PlaylistCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PlaylistResponse:
    playlist = Playlist(
        title=payload.title,
        description=payload.description,
        playlist_type=payload.playlist_type,
        user_id=current_user.id if payload.playlist_type == "custom" else payload.user_id,
        subject_id=payload.subject_id,
    )
    db.add(playlist)
    db.commit()
    db.refresh(playlist)
    return PlaylistResponse.model_validate(playlist)


@router.get("/{playlist_id}", response_model=PlaylistResponse)
def get_playlist(
    playlist_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PlaylistResponse:
    playlist = db.get(Playlist, playlist_id)
    if not playlist:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Playlist not found.")
    if playlist.user_id and playlist.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")
    return PlaylistResponse.model_validate(playlist)
