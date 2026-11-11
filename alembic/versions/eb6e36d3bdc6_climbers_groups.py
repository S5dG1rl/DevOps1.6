"""climbers, groups, group_climbers

Revision ID: eb6e36d3bdc6
Revises: c2459a405a32
Create Date: 2026-11-11

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "eb6e36d3bdc6"
down_revision: str | Sequence[str] | None = "c2459a405a32"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "climbers",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("full_name_encrypted", sa.String(length=500), nullable=False),
        sa.Column("email_encrypted", sa.String(length=500), nullable=True, unique=True),
        sa.Column("email_hash", sa.String(length=64), nullable=True, unique=True),
        sa.Column("birth_date", sa.Date(), nullable=False),
        sa.Column("experience_level", sa.String(length=20), nullable=False),
        sa.Column("medical_clearance", sa.Boolean(), nullable=False),
    )

    op.create_table(
        "groups",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=200), nullable=False, unique=True),
        sa.Column("description", sa.Text(), nullable=True),
    )

    op.create_table(
        "group_climbers",
        sa.Column("group_id", sa.Integer(), nullable=False),
        sa.Column("climber_id", sa.Integer(), nullable=False),
        sa.Column("role", sa.String(length=20), nullable=False),
        sa.ForeignKeyConstraint(["group_id"], ["groups.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["climber_id"], ["climbers.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("group_id", "climber_id"),
    )


def downgrade() -> None:
    op.drop_table("group_climbers")
    op.drop_table("groups")
    op.drop_table("climbers")
