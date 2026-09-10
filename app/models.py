from __future__ import annotations

from datetime import date

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class Mountain(Base):
    __tablename__ = "mountains"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    country: Mapped[str] = mapped_column(String(100), nullable=False)
    region: Mapped[str | None] = mapped_column(String(100), nullable=True)
    height_m: Mapped[int] = mapped_column(Integer, nullable=False)

    ascents: Mapped[list[Ascent]] = relationship(back_populates="mountain")

    __table_args__ = (CheckConstraint("height_m > 0"),)


class Climber(Base):
    __tablename__ = "climbers"

    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    email: Mapped[str | None] = mapped_column(String(200), unique=True, nullable=True)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    experience_level: Mapped[str] = mapped_column(String(20), nullable=False)
    medical_clearance: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )

    memberships: Mapped[list[GroupClimber]] = relationship(back_populates="climber")


class Group(Base):
    __tablename__ = "groups"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    memberships: Mapped[list[GroupClimber]] = relationship(back_populates="group")
    ascents: Mapped[list[Ascent]] = relationship(back_populates="group")


class GroupClimber(Base):
    __tablename__ = "group_climbers"

    group_id: Mapped[int] = mapped_column(
        ForeignKey("groups.id", ondelete="CASCADE"),
        primary_key=True,
    )
    climber_id: Mapped[int] = mapped_column(
        ForeignKey("climbers.id", ondelete="CASCADE"),
        primary_key=True,
    )
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="member")

    group: Mapped[Group] = relationship(back_populates="memberships")
    climber: Mapped[Climber] = relationship(back_populates="memberships")


class Ascent(Base):
    __tablename__ = "ascents"

    id: Mapped[int] = mapped_column(primary_key=True)
    mountain_id: Mapped[int] = mapped_column(
        ForeignKey("mountains.id", ondelete="RESTRICT"),
        nullable=False,
    )
    group_id: Mapped[int] = mapped_column(
        ForeignKey("groups.id", ondelete="RESTRICT"),
        nullable=False,
    )
    route_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="planned")
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    mountain: Mapped[Mountain] = relationship(back_populates="ascents")
    group: Mapped[Group] = relationship(back_populates="ascents")
    reports: Mapped[list[Report]] = relationship(back_populates="ascent")

    __table_args__ = (CheckConstraint("end_date >= start_date"),)


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(primary_key=True)
    ascent_id: Mapped[int] = mapped_column(
        ForeignKey("ascents.id", ondelete="RESTRICT"),
        nullable=False,
    )
    report_type: Mapped[str] = mapped_column(
        String(20), nullable=False, default="final"
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)

    ascent: Mapped[Ascent] = relationship(back_populates="reports")
