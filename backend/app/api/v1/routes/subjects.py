from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.document import Document
from app.models.lecture import Lecture
from app.models.subject import Subject
from app.models.user import User
from app.schemas.lecture import LectureResponse
from app.schemas.subject import SubjectResponse


router = APIRouter()


@router.get("", response_model=list[SubjectResponse])
def list_subjects(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[SubjectResponse]:
    subjects = db.scalars(select(Subject).order_by(Subject.name.asc())).all()
    items: list[SubjectResponse] = []

    for subject in subjects:
        lecture_count = db.scalar(
            select(func.count(Lecture.id))
            .join(Document, Document.id == Lecture.document_id)
            .where(Document.subject_id == subject.id)
            .where(Lecture.owner_user_id == current_user.id)
        ) or 0

        items.append(
            SubjectResponse(
                id=subject.id,
                name=subject.name,
                slug=subject.slug,
                description=subject.description,
                cover_image_url=subject.cover_image_url,
                lecture_count=lecture_count,
            )
        )

    return items


@router.get("/{subject_id}/lectures", response_model=list[LectureResponse])
def list_subject_lectures(
    subject_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[LectureResponse]:
    subject = db.get(Subject, subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subject not found.",
        )

    lectures = db.scalars(
        select(Lecture)
        .join(Document, Document.id == Lecture.document_id)
        .where(Document.subject_id == subject_id)
        .where(Lecture.owner_user_id == current_user.id)
        .order_by(Lecture.created_at.desc())
    ).all()
    return [LectureResponse.model_validate(lecture) for lecture in lectures]
