"""add_email_verification_fields

Revision ID: 20260426_0005
Revises: 20260426_0004
Create Date: 2026-04-26 21:30:00.000000
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "20260426_0005"
down_revision = "20260426_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("email_verified", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column(
        "users",
        sa.Column("verification_token_hash", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("verification_token_expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("verification_sent_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f("ix_users_verification_token_hash"), "users", ["verification_token_hash"], unique=False)
    op.execute("UPDATE users SET email_verified = 1")


def downgrade() -> None:
    op.drop_index(op.f("ix_users_verification_token_hash"), table_name="users")
    op.drop_column("users", "verification_sent_at")
    op.drop_column("users", "verification_token_expires_at")
    op.drop_column("users", "verification_token_hash")
    op.drop_column("users", "email_verified")
