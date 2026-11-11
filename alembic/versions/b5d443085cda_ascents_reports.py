"""ascents, reports

Revision ID: b5d443085cda
Revises: eb6e36d3bdc6
Create Date: 2026-11-11

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b5d443085cda"
down_revision: str | Sequence[str] | None = "eb6e36d3bdc6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "ascents",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("mountain_id", sa.Integer(), nullable=False),
        sa.Column("group_id", sa.Integer(), nullable=False),
        sa.Column("route_name", sa.String(length=200), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["mountain_id"], ["mountains.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["group_id"], ["groups.id"], ondelete="RESTRICT"),
        sa.CheckConstraint("end_date >= start_date"),
    )

    op.create_table(
        "reports",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("ascent_id", sa.Integer(), nullable=False),
        sa.Column("report_type", sa.String(length=20), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["ascent_id"], ["ascents.id"], ondelete="RESTRICT"),
    )


def downgrade() -> None:
    op.drop_table("reports")
    op.drop_table("ascents")
