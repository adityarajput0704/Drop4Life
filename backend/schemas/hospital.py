from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class HospitalCreate(BaseModel):
    name:            str = Field(..., min_length=3, max_length=200)
    phone:           str = Field(..., min_length=10, max_length=15)
    address:         str = Field(..., min_length=5, max_length=300)
    city:            str = Field(..., min_length=2, max_length=100)
    registration_no: str = Field(..., min_length=3, max_length=100)


class HospitalResponse(BaseModel):
    id:              int
    name:            str
    email:           str
    phone:           str
    address:         str
    city:            str
    registration_no: str
    is_verified:     bool
    is_active:       bool
    created_at:      datetime

    class Config:
        from_attributes = True

class HospitalUpdate(BaseModel):
    name:    Optional[str] = Field(None, min_length=3, max_length=200)
    phone:   Optional[str] = Field(None, min_length=10, max_length=15)
    address: Optional[str] = Field(None, min_length=5, max_length=300)
    city:    Optional[str] = Field(None, min_length=2, max_length=100)
    # registration_no is intentionally excluded — cannot be changed after registration

