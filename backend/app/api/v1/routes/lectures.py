from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.audio_track import AudioTrack
from app.models.lecture import Lecture
from app.models.lecture_section import LectureSection
from app.models.user import User
from app.schemas.lecture import LectureResponse, LectureTrackResponse, VoiceUpdateRequest
from app.services.processing_service import ProcessingService
from app.services.storage_service import get_storage_service


router = APIRouter()


@router.get("", response_model=list[LectureResponse])
def list_lectures(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[LectureResponse]:
    lectures = db.scalars(
        select(Lecture)
        .where(Lecture.owner_user_id == current_user.id)
        .order_by(Lecture.created_at.desc())
    ).all()
    return [LectureResponse.model_validate(lecture) for lecture in lectures]


@router.get("/{lecture_id}", response_model=LectureResponse)
def get_lecture(
    lecture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> LectureResponse:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")
    return LectureResponse.model_validate(lecture)


@router.patch("/{lecture_id}/voice", response_model=LectureResponse)
def update_voice(
    lecture_id: str,
    payload: VoiceUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> LectureResponse:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    lecture.voice_option = payload.voice_option
    lecture.tts_voice_code = payload.tts_voice_code
    lecture.status = "audio_pending"
    db.add(lecture)
    db.commit()
    db.refresh(lecture)
    return LectureResponse.model_validate(lecture)


@router.get("/{lecture_id}/tracks", response_model=list[LectureTrackResponse])
def get_lecture_tracks(
    lecture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[LectureTrackResponse]:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    storage = get_storage_service()
    rows = db.execute(
        select(LectureSection, AudioTrack)
        .outerjoin(AudioTrack, AudioTrack.lecture_section_id == LectureSection.id)
        .where(LectureSection.lecture_id == lecture_id)
        .order_by(LectureSection.order_index.asc())
    ).all()

    tracks: list[LectureTrackResponse] = []
    for section, audio_track in rows:
        media_url = storage.to_media_url(audio_track.storage_key) if audio_track and audio_track.storage_key else None
        tracks.append(
            LectureTrackResponse(
                id=audio_track.id if audio_track else section.id,
                section_id=section.id,
                title=section.title,
                order_index=section.order_index,
                duration_seconds=(
                    audio_track.duration_seconds if audio_track else section.estimated_duration_seconds
                ),
                status=audio_track.status if audio_track else "missing",
                media_url=media_url,
            )
        )
    return tracks


@router.post("/{lecture_id}/generate-audio", response_model=LectureResponse)
def generate_audio_for_lecture(
    lecture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> LectureResponse:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    updated_lecture = ProcessingService(db).generate_audio_for_lecture(lecture_id)
    if not updated_lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    return LectureResponse.model_validate(updated_lecture)


@router.post("/{lecture_id}/regenerate-content", response_model=LectureResponse)
def regenerate_lecture_content(
    lecture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> LectureResponse:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    updated_lecture = ProcessingService(db).regenerate_lecture_content(lecture_id)
    if not updated_lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    return LectureResponse.model_validate(updated_lecture)


@router.delete("/{lecture_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_lecture(
    lecture_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    lecture = db.get(Lecture, lecture_id)
    if not lecture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found.")
    if lecture.owner_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    ProcessingService(db)._clear_existing_audio_and_sections(lecture)
    for playlist_link in list(lecture.playlist_links):
        db.delete(playlist_link)
    db.delete(lecture)
    db.commit()
