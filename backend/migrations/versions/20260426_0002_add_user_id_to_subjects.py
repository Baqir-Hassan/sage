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


def _get_column_names(table_name: str) -> set[str]:
    inspector = sa.inspect(op.get_bind())
    return {column["name"] for column in inspector.get_columns(table_name)}


def _get_index_names(table_name: str) -> set[str]:
    inspector = sa.inspect(op.get_bind())
    return {index["name"] for index in inspector.get_indexes(table_name)}


def _get_unique_constraint_names(table_name: str) -> set[str]:
    inspector = sa.inspect(op.get_bind())
    return {constraint["name"] for constraint in inspector.get_unique_constraints(table_name)}


def upgrade() -> None:
    dialect_name = op.get_bind().dialect.name
    subject_columns = _get_column_names("subjects")
    subject_indexes = _get_index_names("subjects")
    subject_unique_constraints = _get_unique_constraint_names("subjects")

    # Add user_id column to subjects table (same type as users.id)
    if "user_id" not in subject_columns:
        op.add_column("subjects", sa.Column("user_id", sa.String(), nullable=True))

    # Create index on user_id
    index_name = op.f("ix_subjects_user_id")
    if index_name not in subject_indexes:
        op.create_index(index_name, "subjects", ["user_id"], unique=False)

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
        if "subjects_name_key" in subject_unique_constraints:
            op.drop_constraint("subjects_name_key", "subjects", type_="unique")
        if "subjects_slug_key" in subject_unique_constraints:
            op.drop_constraint("subjects_slug_key", "subjects", type_="unique")


def downgrade() -> None:
    dialect_name = op.get_bind().dialect.name
    subject_columns = _get_column_names("subjects")
    subject_indexes = _get_index_names("subjects")
    subject_unique_constraints = _get_unique_constraint_names("subjects")

    if dialect_name != "sqlite":
        # Restore unique constraints
        if "subjects_slug_key" not in subject_unique_constraints:
            op.create_unique_constraint("subjects_slug_key", "subjects", ["slug"])
        if "subjects_name_key" not in subject_unique_constraints:
            op.create_unique_constraint("subjects_name_key", "subjects", ["name"])

    # Drop index
    index_name = op.f("ix_subjects_user_id")
    if index_name in subject_indexes:
        op.drop_index(index_name, table_name="subjects")

    if dialect_name != "sqlite":
        # Drop foreign key
        op.drop_constraint("fk_subjects_user_id_users_id", "subjects", type_="foreignkey")

    # Drop column
    if "user_id" in subject_columns:
        op.drop_column("subjects", "user_id")
