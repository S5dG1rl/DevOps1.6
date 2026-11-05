"""dummy migration 1

Revision ID: c2459a405a32
Revises:
Create Date: 2026-11-05 13:47:56.389936

"""

from collections.abc import Sequence

# revision identifiers, used by Alembic.
revision: str = "c2459a405a32"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""


def downgrade() -> None:
    """Downgrade schema."""
