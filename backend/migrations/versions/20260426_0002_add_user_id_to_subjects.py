"""add_user_id_to_subjects

Revision ID: 20260426_0002
Revises: 20260424_0001
Create Date: 2026-04-26 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '20260426_0002'
down_revision = '20260424_0001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add user_id column to subjects table
    op.add_column('subjects', sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')))
    
    # Create foreign key constraint
    op.create_foreign_key('fk_subjects_user_id_users_id', 'subjects', 'users', ['user_id'], ['id'])
    
    # Create index on user_id
    op.create_index(op.f('ix_subjects_user_id'), 'subjects', ['user_id'], unique=False)
    
    # Remove unique constraints from name and slug (since they should only be unique per user)
    op.drop_constraint('subjects_name_key', 'subjects', type_='unique')
    op.drop_constraint('subjects_slug_key', 'subjects', type_='unique')
    
    # Drop server_default after initial data migration
    op.alter_column('subjects', 'user_id', server_default=None)


def downgrade() -> None:
    # Restore unique constraints
    op.create_unique_constraint('subjects_slug_key', 'subjects', ['slug'])
    op.create_unique_constraint('subjects_name_key', 'subjects', ['name'])
    
    # Drop index
    op.drop_index(op.f('ix_subjects_user_id'), table_name='subjects')
    
    # Drop foreign key
    op.drop_constraint('fk_subjects_user_id_users_id', 'subjects', type_='foreignkey')
    
    # Drop column
    op.drop_column('subjects', 'user_id')
