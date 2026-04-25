"""fix_subject_user_id_type_and_backfill

Revision ID: 20260426_0003
Revises: 20260426_0002
Create Date: 2026-04-26 00:30:00.000000
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "20260426_0003"
down_revision = "20260426_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    dialect_name = op.get_bind().dialect.name

    # Ensure subjects.user_id uses the same string type as users.id.
    if dialect_name == "postgresql":
        op.alter_column(
            "subjects",
            "user_id",
            type_=sa.String(),
            existing_nullable=True,
            postgresql_using="user_id::text",
        )

    # Backfill ownership from existing documents for any missing/invalid links.
    op.execute(
        """
        UPDATE subjects AS s
        SET user_id = d.user_id
        FROM (
            SELECT subject_id, MIN(user_id) AS user_id
            FROM documents
            WHERE subject_id IS NOT NULL
            GROUP BY subject_id
        ) AS d
        WHERE s.id = d.subject_id
          AND (
              s.user_id IS NULL
              OR NOT EXISTS (
                  SELECT 1
                  FROM users AS u
                  WHERE u.id = s.user_id
              )
          )
        """
    )


def downgrade() -> None:
    # No safe reverse back to UUID for arbitrary string identifiers.
    pass
