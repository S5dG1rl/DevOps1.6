from datetime import date

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ============================================
# Схемы для аутентификации
# ============================================

class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8)
    role: str = "instructor"


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: str
    is_active: bool
    role: str


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ============================================
# Схемы для Mountain
# ============================================

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


# ============================================
# Схемы для Climber (с автоматическим шифрованием)
# ============================================

class ClimberCreate(BaseModel):
    full_name: str
    email: str | None = None
    birth_date: date
    experience_level: str
    medical_clearance: bool = False


class ClimberRead(BaseModel):
    """Схема для чтения - возвращает дешифрованные данные"""
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: str | None
    birth_date: date
    experience_level: str
    medical_clearance: bool


# ============================================
# Схемы для Group
# ============================================

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


# ============================================
# Схемы для Ascent
# ============================================

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


# ============================================
# Схемы для Report
# ============================================

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
