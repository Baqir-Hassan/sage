"""initial schema

Revision ID: 20260424_0001
Revises:
Create Date: 2026-04-24 16:05:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "20260424_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "subjects",
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("slug", sa.String(length=140), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("cover_image_url", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index(op.f("ix_subjects_name"), "subjects", ["name"], unique=False)
    op.create_index(op.f("ix_subjects_slug"), "subjects", ["slug"], unique=False)

    op.create_table(
        "users",
        sa.Column("full_name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=False)

    op.create_table(
        "documents",
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("subject_id", sa.String(), nullable=True),
        sa.Column("original_filename", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=120), nullable=False),
        sa.Column("storage_key", sa.String(length=500), nullable=False),
        sa.Column("status", sa.String(length=50), nullable=False),
        sa.Column("selected_voice", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_documents_status"), "documents", ["status"], unique=False)
    op.create_index(op.f("ix_documents_subject_id"), "documents", ["subject_id"], unique=False)
    op.create_index(op.f("ix_documents_user_id"), "documents", ["user_id"], unique=False)

    op.create_table(
        "playlists",
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("playlist_type", sa.String(length=20), nullable=False),
        sa.Column("cover_image_url", sa.String(length=500), nullable=True),
        sa.Column("user_id", sa.String(), nullable=True),
        sa.Column("subject_id", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_playlists_playlist_type"), "playlists", ["playlist_type"], unique=False)
    op.create_index(op.f("ix_playlists_subject_id"), "playlists", ["subject_id"], unique=False)
    op.create_index(op.f("ix_playlists_title"), "playlists", ["title"], unique=False)
    op.create_index(op.f("ix_playlists_user_id"), "playlists", ["user_id"], unique=False)

    op.create_table(
        "processing_jobs",
        sa.Column("document_id", sa.String(), nullable=False),
        sa.Column("job_type", sa.String(length=60), nullable=False),
        sa.Column("status", sa.String(length=50), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["document_id"], ["documents.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_processing_jobs_document_id"), "processing_jobs", ["document_id"], unique=False)
    op.create_index(op.f("ix_processing_jobs_job_type"), "processing_jobs", ["job_type"], unique=False)
    op.create_index(op.f("ix_processing_jobs_status"), "processing_jobs", ["status"], unique=False)

    op.create_table(
        "lectures",
        sa.Column("document_id", sa.String(), nullable=False),
        sa.Column("owner_user_id", sa.String(), nullable=False),
        sa.Column("primary_playlist_id", sa.String(), nullable=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("voice_option", sa.String(length=20), nullable=False),
        sa.Column("tts_voice_code", sa.String(length=120), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["document_id"], ["documents.id"]),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["primary_playlist_id"], ["playlists.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_lectures_document_id"), "lectures", ["document_id"], unique=False)
    op.create_index(op.f("ix_lectures_owner_user_id"), "lectures", ["owner_user_id"], unique=False)
    op.create_index(op.f("ix_lectures_primary_playlist_id"), "lectures", ["primary_playlist_id"], unique=False)
    op.create_index(op.f("ix_lectures_status"), "lectures", ["status"], unique=False)

    op.create_table(
        "lecture_sections",
        sa.Column("lecture_id", sa.String(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("script_text", sa.Text(), nullable=False),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("estimated_duration_seconds", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["lecture_id"], ["lectures.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_lecture_sections_lecture_id"), "lecture_sections", ["lecture_id"], unique=False)

    op.create_table(
        "playlist_lectures",
        sa.Column("playlist_id", sa.String(), nullable=False),
        sa.Column("lecture_id", sa.String(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["lecture_id"], ["lectures.id"]),
        sa.ForeignKeyConstraint(["playlist_id"], ["playlists.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("playlist_id", "lecture_id", name="uq_playlist_lecture"),
    )
    op.create_index(op.f("ix_playlist_lectures_lecture_id"), "playlist_lectures", ["lecture_id"], unique=False)
    op.create_index(op.f("ix_playlist_lectures_playlist_id"), "playlist_lectures", ["playlist_id"], unique=False)

    op.create_table(
        "audio_tracks",
        sa.Column("lecture_section_id", sa.String(), nullable=False),
        sa.Column("storage_key", sa.String(length=500), nullable=True),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["lecture_section_id"], ["lecture_sections.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("lecture_section_id"),
    )
    op.create_index(op.f("ix_audio_tracks_status"), "audio_tracks", ["status"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_audio_tracks_status"), table_name="audio_tracks")
    op.drop_table("audio_tracks")

    op.drop_index(op.f("ix_playlist_lectures_playlist_id"), table_name="playlist_lectures")
    op.drop_index(op.f("ix_playlist_lectures_lecture_id"), table_name="playlist_lectures")
    op.drop_table("playlist_lectures")

    op.drop_index(op.f("ix_lecture_sections_lecture_id"), table_name="lecture_sections")
    op.drop_table("lecture_sections")

    op.drop_index(op.f("ix_lectures_status"), table_name="lectures")
    op.drop_index(op.f("ix_lectures_primary_playlist_id"), table_name="lectures")
    op.drop_index(op.f("ix_lectures_owner_user_id"), table_name="lectures")
    op.drop_index(op.f("ix_lectures_document_id"), table_name="lectures")
    op.drop_table("lectures")

    op.drop_index(op.f("ix_processing_jobs_status"), table_name="processing_jobs")
    op.drop_index(op.f("ix_processing_jobs_job_type"), table_name="processing_jobs")
    op.drop_index(op.f("ix_processing_jobs_document_id"), table_name="processing_jobs")
    op.drop_table("processing_jobs")

    op.drop_index(op.f("ix_playlists_user_id"), table_name="playlists")
    op.drop_index(op.f("ix_playlists_title"), table_name="playlists")
    op.drop_index(op.f("ix_playlists_subject_id"), table_name="playlists")
    op.drop_index(op.f("ix_playlists_playlist_type"), table_name="playlists")
    op.drop_table("playlists")

    op.drop_index(op.f("ix_documents_user_id"), table_name="documents")
    op.drop_index(op.f("ix_documents_subject_id"), table_name="documents")
    op.drop_index(op.f("ix_documents_status"), table_name="documents")
    op.drop_table("documents")

    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_table("users")

    op.drop_index(op.f("ix_subjects_slug"), table_name="subjects")
    op.drop_index(op.f("ix_subjects_name"), table_name="subjects")
    op.drop_table("subjects")
