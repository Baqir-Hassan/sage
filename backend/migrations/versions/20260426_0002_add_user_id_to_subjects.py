"""add_user_id_to_subjects

Revision ID: 20260426_0002
Revises: 20260424_0001
Create Date: 2026-04-26 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20260426_0002'
down_revision = '20260424_0001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    dialect_name = op.get_bind().dialect.name

    # Add user_id column to subjects table (same type as users.id)
    op.add_column("subjects", sa.Column("user_id", sa.String(), nullable=True))

    # Create index on user_id
    op.create_index(op.f("ix_subjects_user_id"), "subjects", ["user_id"], unique=False)

    # SQLite does not support ALTER TABLE constraint ops directly.
    if dialect_name != "sqlite":
        # Create foreign key constraint
        op.create_foreign_key(
            "fk_subjects_user_id_users_id",
            "subjects",
            "users",
            ["user_id"],
            ["id"],
        )

        # Remove global unique constraints (now enforced per user at app level)
        op.drop_constraint("subjects_name_key", "subjects", type_="unique")
        op.drop_constraint("subjects_slug_key", "subjects", type_="unique")


def downgrade() -> None:
    dialect_name = op.get_bind().dialect.name

    if dialect_name != "sqlite":
        # Restore unique constraints
        op.create_unique_constraint("subjects_slug_key", "subjects", ["slug"])
        op.create_unique_constraint("subjects_name_key", "subjects", ["name"])

    # Drop index
    op.drop_index(op.f("ix_subjects_user_id"), table_name="subjects")

    if dialect_name != "sqlite":
        # Drop foreign key
        op.drop_constraint("fk_subjects_user_id_users_id", "subjects", type_="foreignkey")

    # Drop column
    op.drop_column("subjects", "user_id")
