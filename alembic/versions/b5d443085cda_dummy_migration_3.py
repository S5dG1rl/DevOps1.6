"""dummy migration 3

Revision ID: b5d443085cda
Revises: eb6e36d3bdc6
Create Date: 2026-11-05 13:48:07.269958

"""

from collections.abc import Sequence

# revision identifiers, used by Alembic.
revision: str = "b5d443085cda"
down_revision: str | Sequence[str] | None = "eb6e36d3bdc6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""


def downgrade() -> None:
    """Downgrade schema."""
