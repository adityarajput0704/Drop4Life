from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
from .donor import BloodGroup
from backend.schemas.hospital import HospitalResponse
from backend.schemas.donor import DonorResponse

class UrgencyLevel(str, Enum):
    Critical = "critical"
    Urgent = "urgent"
    Normal = "normal"

class RequestStatus(str, Enum):
    Active = "active"
    Fulfilled = "fulfilled"
    Cancelled = "cancelled"

class BloodRequestCreate(BaseModel):
    blood_group_needed: BloodGroup
    hospital_id:        int           = Field(..., gt=0)   # ← ADD THIS
    hospital:           str           = Field(..., min_length=3, max_length=200)
    city:               str           = Field(..., min_length=2, max_length=100)
    urgency:            UrgencyLevel
    units_needed:       int           = Field(..., ge=1, le=10)
    patient_name:       str           = Field(..., min_length=2, max_length=100)
    contact_phone:      str           = Field(..., min_length=10, max_length=15)
    notes:              Optional[str] = Field(None, max_length=500)

class BloodRequestUpdate(BaseModel):
    urgency:       Optional[UrgencyLevel]   = None
    status:        Optional[RequestStatus]  = None
    units_needed:  Optional[int]            = Field(None, ge=1, le=10)
    notes:         Optional[str]            = Field(None, max_length=500)



class BloodRequestResponse(BaseModel):
    id: int
    blood_group_needed: BloodGroup
    hospital: str
    city: str
    urgency: UrgencyLevel
    units_needed: int
    patient_name: str
    contact_phone: int
    notes: Optional[str]
    status: RequestStatus

    model_config = {"from_attributes": True}  # allows creating response from ORM models

class BloodRequestListResponse(BaseModel):
    total: int
    filters_applied: Optional[dict] = None
    blood_requests: list[BloodRequestResponse]

