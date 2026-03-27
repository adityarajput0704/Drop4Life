from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    """Used when a new user registers — sent from frontend after Firebase signup"""
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    blood_group: Optional[str] = None


class UserUpdate(BaseModel):
    """Partial updates — all fields optional"""
    full_name: Optional[str] = None
    phone: Optional[str] = None
    blood_group: Optional[str] = None


class UserResponse(BaseModel):
    """What we send back — never expose sensitive fields"""
    id: str
    email: str
    full_name: str
    phone: Optional[str]
    blood_group: Optional[str]
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True