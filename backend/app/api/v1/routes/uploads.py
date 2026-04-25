from pathlib import Path
import re
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.document import Document
from app.models.lecture import Lecture
from app.models.processing_job import ProcessingJob
from app.models.subject import Subject
from app.models.user import User
from app.schemas.upload import (
    UploadLimitsResponse,
    UploadListItemResponse,
    UploadResponse,
    UploadStatusResponse,
    VoiceOption,
)
from app.services.processing_service import ProcessingService
from app.services.queue_service import get_queue_service
from app.services.storage_service import get_storage_service
from app.services.usage_limit_service import DailyLimitExceededError, UsageLimitService


router = APIRouter()

ALLOWED_UPLOAD_EXTENSIONS = {".pdf", ".pptx"}
ALLOWED_UPLOAD_CONTENT_TYPES = {
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


@router.get("/limits", response_model=UploadLimitsResponse)
def get_upload_limits(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UploadLimitsResponse:
    summary = UsageLimitService(db).build_usage_summary(current_user.id)
    return UploadLimitsResponse(**summary)


@router.post("", response_model=UploadResponse, status_code=status.HTTP_202_ACCEPTED)
async def upload_document(
    file: UploadFile = File(...),
    voice_option: VoiceOption = Form(...),
    subject_id: str | None = Form(default=None),
    subject_name: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UploadResponse:
    try:
        UsageLimitService(db).enforce_new_lecture_limit(current_user.id)
    except DailyLimitExceededError as exc:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=exc.detail) from exc

    filename = file.filename or "upload"
    extension = Path(filename).suffix.lower()
    content_type = file.content_type or "application/octet-stream"
    if extension not in ALLOWED_UPLOAD_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF and PPTX files are supported.",
        )
    if content_type != "application/octet-stream" and content_type not in ALLOWED_UPLOAD_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF and PPTX files are supported.",
        )

    storage = get_storage_service()
    file_bytes = await file.read()
    storage_key = storage.save_upload(filename, file_bytes)
    resolved_subject_id = _resolve_subject_selection(db, subject_id, subject_name, current_user)

    document = Document(
        id=str(uuid4()),
        user_id=current_user.id,
        original_filename=filename,
        content_type=content_type,
        storage_key=storage_key,
        status="uploaded",
        subject_id=resolved_subject_id,
        selected_voice=voice_option.value,
    )
    db.add(document)

    job = ProcessingJob(
        id=str(uuid4()),
        document_id=document.id,
        job_type="document_ingestion",
        status="queued",
    )
    db.add(job)
    db.commit()

    get_queue_service().enqueue_document_processing(document.id)

    return UploadResponse(
        document_id=document.id,
        processing_job_id=job.id,
        status=job.status,
    )


@router.get("", response_model=list[UploadListItemResponse])
def list_uploads(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[UploadListItemResponse]:
    documents = db.scalars(
        select(Document)
        .where(Document.user_id == current_user.id)
        .order_by(Document.created_at.desc())
    ).all()

    items: list[UploadListItemResponse] = []
    for document in documents:
        lecture = db.scalar(
            select(Lecture).where(Lecture.document_id == document.id).order_by(Lecture.created_at.desc())
        )
        items.append(
            UploadListItemResponse(
                document_id=document.id,
                original_filename=document.original_filename,
                content_type=document.content_type,
                document_status=document.status,
                selected_voice=document.selected_voice,
                lecture_id=lecture.id if lecture else None,
            )
        )
    return items


@router.get("/{document_id}/status", response_model=UploadStatusResponse)
def get_upload_status(
    document_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UploadStatusResponse:
    document = db.get(Document, document_id)
    if not document:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")
    if document.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    job = db.scalar(
        select(ProcessingJob)
        .where(ProcessingJob.document_id == document_id)
        .order_by(ProcessingJob.created_at.desc())
    )
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Processing job not found for document.",
        )

    lecture = db.scalar(
        select(Lecture)
        .where(Lecture.document_id == document_id)
        .order_by(Lecture.created_at.desc())
    )

    return UploadStatusResponse(
        document_id=document.id,
        document_status=document.status,
        processing_job_id=job.id,
        processing_status=job.status,
        selected_voice=document.selected_voice,
        lecture_id=lecture.id if lecture else None,
    )


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_upload(
    document_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    document = db.get(Document, document_id)
    if not document:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")
    if document.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")

    storage = get_storage_service()

    lectures = db.scalars(select(Lecture).where(Lecture.document_id == document.id)).all()
    for lecture in lectures:
        ProcessingService(db)._clear_existing_audio_and_sections(lecture)
        for playlist_link in list(lecture.playlist_links):
            db.delete(playlist_link)
        db.delete(lecture)

    for job in list(document.processing_jobs):
        db.delete(job)

    try:
        storage.delete(document.storage_key)
    except (FileNotFoundError, ValueError):
        pass

    db.delete(document)
    db.commit()


def _resolve_subject_selection(db: Session, subject_id: str | None, subject_name: str | None, current_user: User) -> str | None:
    normalized_subject_name = (subject_name or "").strip()
    if normalized_subject_name:
        base_slug = _slugify_subject_name(normalized_subject_name)
        candidate_slug = base_slug
        suffix = 2

        while True:
            existing = db.scalar(
                select(Subject)
                .where(Subject.slug == candidate_slug)
                .where(Subject.user_id == current_user.id)
            )
            if existing is None:
                subject = Subject(
                    name=normalized_subject_name,
                    slug=candidate_slug,
                    user_id=current_user.id,
                )
                db.add(subject)
                db.flush()
                return subject.id
            if existing.name.lower() == normalized_subject_name.lower():
                return existing.id
            candidate_slug = f"{base_slug}-{suffix}"
            suffix += 1

    if subject_id:
        # Verify that the subject exists and belongs to the current user
        subject = db.get(Subject, subject_id)
        if subject and subject.user_id == current_user.id:
            return subject_id
        # If subject doesn't exist or doesn't belong to user, return None
        return None

    return None


def _slugify_subject_name(subject_name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", subject_name.lower()).strip("-")
    return slug or "general"
