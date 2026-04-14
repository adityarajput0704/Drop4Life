from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum
from fastapi import Query


class UrgencyLevel(str, Enum):
    LOW      = "low"
    MEDIUM   = "medium"
    HIGH     = "high"
    CRITICAL = "critical"


class RequestStatus(str, Enum):
    OPEN      = "open"
    ACCEPTED  = "accepted"
    FULFILLED = "fulfilled"
    CANCELLED = "cancelled"


class BloodGroup(str, Enum):
    A_POS  = "A+"
    A_NEG  = "A-"
    B_POS  = "B+"
    B_NEG  = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS  = "O+"
    O_NEG  = "O-"


class BloodRequestCreate(BaseModel):
    blood_group:   BloodGroup
    units_needed:  int = Field(default=1, ge=1, le=10)
    patient_name:  str = Field(..., min_length=2, max_length=200)
    urgency:       UrgencyLevel = Field(default=UrgencyLevel.MEDIUM)
    notes:         Optional[str] = Field(None, max_length=500)


class BloodRequestResponse(BaseModel):
    id:            int
    blood_group:   BloodGroup
    units_needed:  int
    patient_name:  str
    urgency:       UrgencyLevel
    status:        RequestStatus
    notes:         Optional[str]
    created_at:    datetime

    # Hospital info
    hospital_name: str
    hospital_city: str
    hospital_phone: str
    # Hospital location — for Flutter map
    hospital_lat:   Optional[float] = None    
    hospital_lng:   Optional[float] = None   
    # Donor info — null until accepted
    donor_name:    Optional[str] = None
    donor_phone:   Optional[str] = None

    model_config = {"from_attributes": True}


class BloodRequestListResponse(BaseModel):
    total:    int
    items: list[BloodRequestResponse]

class RequestFilterParams:
    """
    Query parameter filters for blood request listing.
    Each field is optional — only applied if provided.
    """
    def __init__(
        self,
        blood_group:      Optional[str]         = Query(default=None, description="Filter by blood group e.g. A+"),
        urgency:          Optional[UrgencyLevel] = Query(default=None, description="Filter by urgency level"),
        status:           Optional[str]          = Query(default=None, description="Filter by status"),
        city:             Optional[str]          = Query(default=None, description="Filter by hospital city"),
        units_needed_min: Optional[int]          = Query(default=None, ge=1, description="Minimum units needed"),
    ):
        self.blood_group      = blood_group
        self.urgency          = urgency
        self.status           = status
        self.city             = city
        self.units_needed_min = units_needed_min