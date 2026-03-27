# app/schemas/hospital.py

from pydantic import BaseModel, Field, field_validator, EmailStr
from typing import Optional
from .donor import BloodGroup  # reuse — never duplicate enums


# ── REQUEST SCHEMAS ─────────────────────────────────────────────────

class HospitalCreate(BaseModel):
    name:             str            = Field(..., min_length=4,  max_length=200)
    address:          str            = Field(..., min_length=10, max_length=500)
    city:             str            = Field(..., min_length=2,  max_length=100)
    phone:            str            = Field(..., min_length=10, max_length=16)
    email:            Optional[EmailStr] = None   # EmailStr validates format automatically
    verified:         bool           = Field(default=False)
    blood_inventory:  Optional[dict[BloodGroup, int]] = Field(default_factory=dict)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str) -> str:
        value = value.strip()
        cleaned = value.lstrip("+").replace("-", "").replace(" ", "")
        if not cleaned.isdigit():
            raise ValueError("Phone must contain only digits, +, -, or spaces")
        if not (10 <= len(cleaned) <= 15):
            raise ValueError("Phone must be 10–15 digits")
        # Normalize: always store with leading +
        return "+" + cleaned

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        # Allow letters, spaces, dots, hyphens (e.g. "St. Mary's" won't pass isalpha)
        stripped = value.replace(" ", "").replace(".", "").replace("-", "").replace("'", "")
        if not stripped.isalpha():
            raise ValueError("Name must contain only letters, spaces, dots, or hyphens")
        return value.strip().title()


class HospitalUpdate(BaseModel):
    """All fields optional — PATCH semantics"""
    name:            Optional[str]              = Field(None, min_length=4, max_length=200)
    address:         Optional[str]              = Field(None, min_length=10, max_length=500)
    city:            Optional[str]              = Field(None, min_length=2, max_length=100)
    phone:           Optional[str]              = None
    email:           Optional[EmailStr]         = None
    verified:        Optional[bool]             = None
    blood_inventory: Optional[dict[BloodGroup, int]] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        cleaned = value.strip().lstrip("+").replace("-", "").replace(" ", "")
        if not cleaned.isdigit():
            raise ValueError("Phone must contain only digits, +, -, or spaces")
        if not (10 <= len(cleaned) <= 15):
            raise ValueError("Phone must be 10 to 15 digits")
        return "+" + cleaned

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.replace(" ", "").replace(".", "").replace("-", "").replace("'", "")
        if not stripped.isalpha():
            raise ValueError("Name must contain only letters, spaces, dots, or hyphens")
        return value.strip().title()


# ── RESPONSE SCHEMAS ────────────────────────────────────────────────

class HospitalResponse(BaseModel):
    id:              int
    name:            str
    address:         str
    city:            str
    phone:           str
    email:           Optional[str] = None
    verified:        bool                        # real bool, never string
    blood_inventory: dict[BloodGroup, int] = Field(default_factory=dict)

    model_config = {"from_attributes": True}


class HospitalListResponse(BaseModel):
    total:           int
    filters_applied: dict = Field(default_factory=dict)
    hospitals:       list[HospitalResponse]