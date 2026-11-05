"""dummy migration 2

Revision ID: eb6e36d3bdc6
Revises: c2459a405a32
Create Date: 2026-11-05 13:48:02.138914

"""

from collections.abc import Sequence

# revision identifiers, used by Alembic.
revision: str = "eb6e36d3bdc6"
down_revision: str | Sequence[str] | None = "c2459a405a32"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""


def downgrade() -> None:
    """Downgrade schema."""
