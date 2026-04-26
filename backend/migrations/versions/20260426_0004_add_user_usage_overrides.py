"""add_user_usage_overrides

Revision ID: 20260426_0004
Revises: 20260426_0003
Create Date: 2026-04-26 20:20:00.000000
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "20260426_0004"
down_revision = "20260426_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("is_admin", sa.Boolean(), nullable=False, server_default=sa.false()),
    )

    op.create_table(
        "user_usage_overrides",
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("daily_new_lecture_limit", sa.Integer(), nullable=True),
        sa.Column("daily_regeneration_limit", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(op.f("ix_user_usage_overrides_user_id"), "user_usage_overrides", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_user_usage_overrides_user_id"), table_name="user_usage_overrides")
    op.drop_table("user_usage_overrides")
    op.drop_column("users", "is_admin")
