from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class MountainCreate(BaseModel):
    name: str
    country: str
    region: str | None = None
    height_m: int = Field(gt=0)


class MountainRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    country: str
    region: str | None
    height_m: int


class ClimberCreate(BaseModel):
    full_name: str
    email: str | None = None
    birth_date: date
    experience_level: str
    medical_clearance: bool = False


class ClimberRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: str | None
    birth_date: date
    experience_level: str
    medical_clearance: bool


class GroupCreate(BaseModel):
    name: str
    description: str | None = None


class GroupRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None


class GroupClimberCreate(BaseModel):
    climber_id: int
    role: str = "member"


class GroupClimberRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    group_id: int
    climber_id: int
    role: str


class AscentCreate(BaseModel):
    mountain_id: int
    group_id: int
    route_name: str | None = None
    start_date: date
    end_date: date
    notes: str | None = None


class AscentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    mountain_id: int
    group_id: int
    route_name: str | None
    status: str
    start_date: date
    end_date: date
    notes: str | None


class ReportCreate(BaseModel):
    ascent_id: int
    report_type: str = "final"
    title: str
    summary: str


class ReportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    ascent_id: int
    report_type: str
    title: str
    summary: str
