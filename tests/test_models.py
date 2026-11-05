from datetime import date

import pytest
from sqlalchemy.exc import IntegrityError

from app.models import Ascent, Group, Mountain


def test_mountain_height_zero(db_session):

    m = Mountain(name="Zero", country="X", height_m=0)

    db_session.add(m)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_mountain_height_negative(db_session):

    m = Mountain(name="Neg", country="X", height_m=-10)

    db_session.add(m)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()


def test_ascent_dates_invalid(db_session):

    m = Mountain(name="M1", country="C", height_m=100)

    g = Group(name="G1")

    db_session.add_all([m, g])

    db_session.commit()

    a = Ascent(
        mountain_id=m.id,
        group_id=g.id,
        start_date=date(2024, 5, 10),
        end_date=date(2024, 5, 5),
    )

    db_session.add(a)

    with pytest.raises(IntegrityError):
        db_session.commit()

    db_session.rollback()
