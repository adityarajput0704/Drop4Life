from pydantic import BaseModel, Field, field_validator
from typing import Optional
from enum import Enum
from fastapi import Query
from pydantic import BaseModel as PydanticBase

class LocationUpdate(PydanticBase):
    latitude:  float = Field(..., ge=-90,  le=90)
    longitude: float = Field(..., ge=-180, le=180)

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
    id:              int
    blood_group:     BloodGroup
    city:            str
    age:             int
    availability:    AvailabilityStatus
    is_active:       bool
    full_name:       str
    email:           str
    phone:           Optional[str]
    total_donations: int = 0
    lives_saved:     int = 0
    last_donation:   Optional[str] = None
    is_in_cooldown:  bool = False
    cooldown_until:  Optional[str] = None
    days_remaining:  int = 0
    # Location
    latitude:        Optional[float] = None
    longitude:       Optional[float] = None
    distance_km:     Optional[float] = None   # ← computed, not stored

    model_config = {"from_attributes": True}


class DonorListResponse(BaseModel):
    total:  int
    donors: list[DonorResponse]



class DonorFilterParams:
    def __init__(
        self,
        blood_group:  Optional[str]   = Query(default=None),
        city:         Optional[str]   = Query(default=None),
        is_available: Optional[bool]  = Query(default=None),
        search:       Optional[str]   = Query(default=None),
        # New location params
        lat:          Optional[float] = Query(default=None, description="Requester latitude"),
        lng:          Optional[float] = Query(default=None, description="Requester longitude"),
        radius_km:    Optional[float] = Query(default=None, description="Search radius in km"),
    ):
        self.blood_group  = blood_group
        self.city         = city
        self.is_available = is_available
        self.search       = search
        self.lat          = lat
        self.lng          = lng
        self.radius_km    = radius_km