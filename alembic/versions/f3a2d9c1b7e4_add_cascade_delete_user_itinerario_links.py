"""add cascade delete for user itinerario links

Revision ID: f3a2d9c1b7e4
Revises: ebc41a91fd7e
Create Date: 2026-09-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = 'f3a2d9c1b7e4'
down_revision: Union[str, Sequence[str], None] = 'ebc41a91fd7e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_constraint('itinerarios_ibfk_1', 'itinerarios', type_='foreignkey')
    op.create_foreign_key(
        'itinerarios_ibfk_1',
        'itinerarios',
        'usuarios',
        ['idUsuario'],
        ['id'],
        ondelete='CASCADE',
    )

    op.drop_constraint('items_itinerario_ibfk_1', 'items_itinerario', type_='foreignkey')
    op.create_foreign_key(
        'items_itinerario_ibfk_1',
        'items_itinerario',
        'itinerarios',
        ['idItinerario'],
        ['id'],
        ondelete='CASCADE',
    )

    op.drop_constraint('dias_itinerario_ibfk_1', 'dias_itinerario', type_='foreignkey')
    op.create_foreign_key(
        'dias_itinerario_ibfk_1',
        'dias_itinerario',
        'itinerarios',
        ['idItinerario'],
        ['id'],
        ondelete='CASCADE',
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('dias_itinerario_ibfk_1', 'dias_itinerario', type_='foreignkey')
    op.create_foreign_key(
        'dias_itinerario_ibfk_1',
        'dias_itinerario',
        'itinerarios',
        ['idItinerario'],
        ['id'],
    )

    op.drop_constraint('items_itinerario_ibfk_1', 'items_itinerario', type_='foreignkey')
    op.create_foreign_key(
        'items_itinerario_ibfk_1',
        'items_itinerario',
        'itinerarios',
        ['idItinerario'],
        ['id'],
    )

    op.drop_constraint('itinerarios_ibfk_1', 'itinerarios', type_='foreignkey')
    op.create_foreign_key(
        'itinerarios_ibfk_1',
        'itinerarios',
        'usuarios',
        ['idUsuario'],
        ['id'],
    )
