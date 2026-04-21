from math import ceil
from pathlib import Path
import re
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.audio_track import AudioTrack
from app.models.document import Document
from app.models.lecture import Lecture
from app.models.lecture_section import LectureSection
from app.models.playlist import Playlist
from app.models.playlist_lecture import PlaylistLecture
from app.models.processing_job import ProcessingJob
from app.models.subject import Subject
from app.services.audio_service import AudioGenerationService
from app.services.groq_service import GroqService
from app.services.parser_service import ParserService
from app.services.storage_service import LocalStorageService
from app.services.voice_service import resolve_tts_voice


class ProcessingService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.parser = ParserService()
        self.llm = GroqService()
        self.storage = LocalStorageService()
        self.audio = AudioGenerationService()

    def process_document(self, document_id: str) -> None:
        document = self.db.get(Document, document_id)
        if not document:
            return

        job = self.db.scalar(
            select(ProcessingJob)
            .where(ProcessingJob.document_id == document_id)
            .order_by(ProcessingJob.created_at.desc())
        )
        if not job:
            return

        try:
            job.status = "processing"
            document.status = "processing"
            self.db.commit()

            extracted_text = self._extract_text_for_document(document)
            lecture_payload = self.llm.generate_lecture_script(
                prompt=self._build_prompt(document.original_filename, extracted_text)
            )

            subject = self._resolve_subject(document, lecture_payload)
            playlist = self._resolve_playlist(document, subject, lecture_payload)
            lecture = self._create_lecture(document, playlist, lecture_payload)
            self._create_sections(lecture, lecture_payload, extracted_text)
            self.db.flush()
            self._create_audio_tracks(lecture)

            if not self.db.scalar(
                select(PlaylistLecture).where(
                    PlaylistLecture.playlist_id == playlist.id,
                    PlaylistLecture.lecture_id == lecture.id,
                )
            ):
                self.db.add(
                    PlaylistLecture(
                        playlist_id=playlist.id,
                        lecture_id=lecture.id,
                        position=0,
                    )
                )

            document.subject_id = subject.id
            document.status = "ready"
            lecture.status = "ready"
            job.status = "completed"
            self.db.commit()
        except Exception as exc:
            job.status = "failed"
            job.error_message = str(exc)
            document.status = "failed"
            self.db.commit()
            raise

    def generate_audio_for_lecture(self, lecture_id: str) -> Lecture | None:
        lecture = self.db.get(Lecture, lecture_id)
        if not lecture:
            return None

        lecture.status = "audio_processing"
        self.db.commit()
        self._create_audio_tracks(lecture)
        lecture.status = "ready"
        self.db.commit()
        self.db.refresh(lecture)
        return lecture

    def regenerate_lecture_content(self, lecture_id: str) -> Lecture | None:
        lecture = self.db.get(Lecture, lecture_id)
        if not lecture:
            return None

        document = lecture.document
        if not document:
            return None

        extracted_text = self._extract_text_for_document(document)
        lecture_payload = self.llm.generate_lecture_script(
            prompt=self._build_prompt(document.original_filename, extracted_text)
        )

        self._clear_existing_audio_and_sections(lecture)

        lecture.title = lecture_payload.get("lecture_title") or lecture.title
        lecture.description = lecture_payload.get("lecture_description") or lecture.description
        lecture.tts_voice_code = resolve_tts_voice(lecture.voice_option)
        lecture.status = "script_ready"
        self.db.flush()

        self._create_sections(lecture, lecture_payload, extracted_text)
        self.db.flush()
        self._create_audio_tracks(lecture)
        lecture.status = "ready"
        self.db.commit()
        self.db.refresh(lecture)
        return lecture

    def _build_prompt(self, filename: str, extracted_text: str) -> str:
        return (
            "You are creating an audio lecture from class notes. "
            "Return valid JSON only with keys subject, playlist_title, lecture_title, lecture_description, and sections. "
            "If the full lecture would be shorter than 6 minutes, return exactly 1 section. "
            "Only split into multiple sections when the full lecture is likely longer than 6 minutes, "
            "and in that case keep the number of sections modest. "
            "Each section must contain title and script. "
            "Each script should sound like a spoken lecture, not bullet points, and should usually be between 120 and 220 words. "
            "Expand abbreviations, connect ideas naturally, and explain the meaning of keywords from the notes. "
            "Do not use markdown, code fences, or extra text outside the JSON.\n"
            f"Filename: {filename}\n"
            f"Notes:\n{extracted_text[:12000]}"
        )

    def _resolve_subject(self, document: Document, lecture_payload: dict) -> Subject:
        if document.subject_id:
            subject = self.db.get(Subject, document.subject_id)
            if subject:
                return subject

        subject_name = lecture_payload.get("subject") or "General"
        slug = subject_name.lower().replace(" ", "-")
        subject = self.db.scalar(select(Subject).where(Subject.slug == slug))
        if subject:
            return subject

        subject = Subject(name=subject_name, slug=slug)
        self.db.add(subject)
        self.db.flush()
        return subject

    def _resolve_playlist(self, document: Document, subject: Subject, lecture_payload: dict) -> Playlist:
        playlist_title = lecture_payload.get("playlist_title") or subject.name
        existing = self.db.scalar(
            select(Playlist).where(
                Playlist.title == playlist_title,
                Playlist.subject_id == subject.id,
                Playlist.playlist_type == "system",
            )
        )
        if existing:
            return existing

        playlist = Playlist(
            title=playlist_title,
            description=f"System playlist for {subject.name} notes.",
            playlist_type="system",
            subject_id=subject.id,
            user_id=document.user_id,
        )
        self.db.add(playlist)
        self.db.flush()
        return playlist

    def _create_lecture(self, document: Document, playlist: Playlist, lecture_payload: dict) -> Lecture:
        existing = self.db.scalar(select(Lecture).where(Lecture.document_id == document.id))
        if existing:
            return existing

        lecture = Lecture(
            document_id=document.id,
            owner_user_id=document.user_id,
            primary_playlist_id=playlist.id,
            title=lecture_payload.get("lecture_title") or document.original_filename,
            description=lecture_payload.get("lecture_description") or "Generated from uploaded notes.",
            voice_option=document.selected_voice,
            tts_voice_code=resolve_tts_voice(document.selected_voice),
            status="script_ready",
        )
        self.db.add(lecture)
        self.db.flush()
        return lecture

    def _create_sections(self, lecture: Lecture, lecture_payload: dict, extracted_text: str) -> None:
        existing_sections = self._get_sections_for_lecture(lecture.id)
        if existing_sections:
            return

        sections = lecture_payload.get("sections") or []
        if not sections:
            sections = self._fallback_sections(extracted_text)
        sections = self._normalize_sections(sections)

        for index, section in enumerate(sections, start=1):
            script_text = section.get("script") or section.get("content") or ""
            self.db.add(
                LectureSection(
                    lecture_id=lecture.id,
                    title=section.get("title") or f"Section {index}",
                    script_text=script_text.strip(),
                    order_index=index,
                    estimated_duration_seconds=max(30, ceil(len(script_text.split()) / 2.5)),
                )
            )

    def _fallback_sections(self, extracted_text: str) -> list[dict[str, str]]:
        paragraphs = [part.strip() for part in extracted_text.split("\n\n") if part.strip()]
        if not paragraphs:
            paragraphs = ["Your document was uploaded successfully, but no readable text was extracted yet."]
        trimmed = paragraphs[:5]
        return [
            {
                "title": f"Section {index}",
                "script": self._expand_into_spoken_script(paragraph, index),
            }
            for index, paragraph in enumerate(trimmed, start=1)
        ]

    def _normalize_sections(self, sections: list[dict[str, str]]) -> list[dict[str, str]]:
        cleaned_sections: list[dict[str, str]] = []
        for index, section in enumerate(sections, start=1):
            title = (section.get("title") or f"Section {index}").strip()
            script = (section.get("script") or section.get("content") or "").strip()
            if not script:
                continue
            cleaned_sections.append({"title": title, "script": script})

        if not cleaned_sections:
            return []

        total_duration = sum(self._estimate_duration_seconds(section["script"]) for section in cleaned_sections)
        if total_duration <= 360:
            merged_title = cleaned_sections[0]["title"] if len(cleaned_sections) == 1 else "Full Lecture"
            merged_script = "\n\n".join(section["script"] for section in cleaned_sections)
            return [{"title": merged_title, "script": merged_script}]

        return cleaned_sections

    def _expand_into_spoken_script(self, raw_text: str, index: int) -> str:
        lines = [line.strip(" -\t") for line in raw_text.splitlines() if line.strip()]
        if not lines:
            return (
                f"This is section {index}. The uploaded material did not contain enough readable text "
                "to generate a detailed lecture for this part."
            )

        topic = lines[0].rstrip(":")
        bullet_lines = lines[1:] or lines[:1]
        normalized_points = [self._normalize_point_text(line) for line in bullet_lines[:8]]
        spoken_points = " ".join(
            f"A key idea here is {point}." for point in normalized_points if point
        )
        return (
            f"In section {index}, we focus on {topic}. "
            f"{spoken_points} "
            f"Taken together, these points explain the main idea behind {topic} "
            "and give a foundation for the rest of the lecture."
        ).strip()

    def _normalize_point_text(self, text: str) -> str:
        cleaned = re.sub(r"\s+", " ", text).strip(" ,.;:-")
        if not cleaned:
            return ""
        if cleaned.lower().startswith("slide "):
            return cleaned
        if cleaned[0].islower():
            cleaned = cleaned[0].upper() + cleaned[1:]
        if cleaned.endswith("."):
            cleaned = cleaned[:-1]
        return cleaned

    def _estimate_duration_seconds(self, script_text: str) -> int:
        return max(30, ceil(len(script_text.split()) / 2.5))

    def _create_audio_tracks(self, lecture: Lecture) -> None:
        voice_code = lecture.tts_voice_code or resolve_tts_voice(lecture.voice_option)
        for section in self._get_sections_for_lecture(lecture.id):
            existing_track = self.db.scalar(
                select(AudioTrack).where(AudioTrack.lecture_section_id == section.id)
            )
            if existing_track:
                continue

            output_path = self.storage.build_audio_path(lecture.id, section.id)
            track = AudioTrack(
                lecture_section_id=section.id,
                storage_key=str(output_path),
                duration_seconds=section.estimated_duration_seconds,
                status="processing",
            )
            self.db.add(track)
            self.db.flush()

            self.audio.generate_section_audio(section.script_text, voice_code, output_path)
            track.status = "ready"

    def _clear_existing_audio_and_sections(self, lecture: Lecture) -> None:
        for section in self._get_sections_for_lecture(lecture.id):
            if section.audio_track:
                storage_key = section.audio_track.storage_key
                if storage_key:
                    audio_path = self.storage.resolve_storage_path(storage_key)
                    if audio_path.exists():
                        audio_path.unlink()
                self.db.delete(section.audio_track)
            self.db.delete(section)
        self.db.flush()
        lecture.sections = []

    def _extract_text_for_document(self, document: Document) -> str:
        resolved_storage_path = self.storage.resolve_storage_path(document.storage_key)
        if document.storage_key != str(resolved_storage_path):
            document.storage_key = str(resolved_storage_path)
            self.db.commit()
        return self.parser.extract_text(document.storage_key, document.content_type)

    def _get_sections_for_lecture(self, lecture_id: str) -> list[LectureSection]:
        return self.db.scalars(
            select(LectureSection)
            .where(LectureSection.lecture_id == lecture_id)
            .order_by(LectureSection.order_index.asc())
        ).all()
