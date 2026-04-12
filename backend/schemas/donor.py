from pydantic import BaseModel, Field, field_validator
from typing import Optional
from enum import Enum
from fastapi import Query

class BloodGroup(str, Enum):
    A_POS  = "A+"
    A_NEG  = "A-"
    B_POS  = "B+"
    B_NEG  = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS  = "O+"
    O_NEG  = "O-"


class AvailabilityStatus(str, Enum):
    AVAILABLE   = "available"
    UNAVAILABLE = "unavailable"
    BUSY        = "busy"


class DonorCreate(BaseModel):
    """Only donor-specific fields — no name/email/phone"""
    blood_group:  BloodGroup
    city:         str = Field(..., example="Mumbai")
    age:          int = Field(..., ge=18, le=65)
    availability: AvailabilityStatus = Field(default=AvailabilityStatus.AVAILABLE)


class DonorUpdate(BaseModel):
    city:         Optional[str] = None
    age:          Optional[int] = Field(None, ge=18, le=65)
    availability: Optional[AvailabilityStatus] = None


class DonorResponse(BaseModel):
    id:                int
    blood_group:       BloodGroup
    city:              str
    age:               int
    availability:      AvailabilityStatus
    is_active:         bool
    full_name:         str
    email:             str
    phone:             Optional[str]
    total_donations:   int = 0
    lives_saved:       int = 0
    last_donation:     Optional[str] = None

    # Cooldown fields — Flutter reads these to lock UI
    is_in_cooldown:    bool = False
    cooldown_until:    Optional[str] = None   # ISO date string "2025-07-10"
    days_remaining:    int = 0                # how many days left

    model_config = {"from_attributes": True}


class DonorListResponse(BaseModel):
    total:  int
    donors: list[DonorResponse]



class DonorFilterParams:
    """
    Query parameter filters for donor listing.
    Each field is optional — only applied if provided.
    """
    def __init__(
        self,
        blood_group: Optional[str] = Query(default=None, description="Filter by blood group e.g. A+"),
        city: Optional[str] = Query(default=None, description="Filter by city"),
        is_available: Optional[bool] = Query(default=None, description="Filter by availability"),
        search: Optional[str] = Query(default=None, description="Search by name or phone"),
    ):
        self.blood_group = blood_group
        self.city = city
        self.is_available = is_available
        self.search = search