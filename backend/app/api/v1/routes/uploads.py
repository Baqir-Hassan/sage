from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.document import Document
from app.models.lecture import Lecture
from app.models.processing_job import ProcessingJob
from app.models.user import User
from app.schemas.upload import UploadListItemResponse, UploadResponse, UploadStatusResponse, VoiceOption
from app.services.processing_service import ProcessingService
from app.services.storage_service import LocalStorageService


router = APIRouter()


@router.post("", response_model=UploadResponse, status_code=status.HTTP_202_ACCEPTED)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    voice_option: VoiceOption = Form(...),
    subject_id: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UploadResponse:
    storage = LocalStorageService()
    file_bytes = await file.read()
    storage_key = storage.save_upload(file.filename or "upload", file_bytes)

    document = Document(
        id=str(uuid4()),
        user_id=current_user.id,
        original_filename=file.filename or "upload",
        content_type=file.content_type or "application/octet-stream",
        storage_key=storage_key,
        status="uploaded",
        subject_id=subject_id,
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

    background_tasks.add_task(run_processing_job, document.id)

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

    storage = LocalStorageService()

    lectures = db.scalars(select(Lecture).where(Lecture.document_id == document.id)).all()
    for lecture in lectures:
        ProcessingService(db)._clear_existing_audio_and_sections(lecture)
        for playlist_link in list(lecture.playlist_links):
            db.delete(playlist_link)
        db.delete(lecture)

    for job in list(document.processing_jobs):
        db.delete(job)

    try:
        source_path = storage.resolve_storage_path(document.storage_key)
        if source_path.exists():
            source_path.unlink()
    except FileNotFoundError:
        pass

    db.delete(document)
    db.commit()


def run_processing_job(document_id: str) -> None:
    from app.db.session import SessionLocal

    db = SessionLocal()
    try:
        ProcessingService(db).process_document(document_id)
    finally:
        db.close()
