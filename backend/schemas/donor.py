from pydantic import BaseModel, Field, field_validator
from typing import Optional
from enum import Enum

class BloodGroup(str, Enum):
    A_POS = "A+"
    A_NEG = "A-"
    B_POS = "B+"
    B_NEG = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS = "O+"
    O_NEG = "O-"

class AvailabilityStatus(str, Enum):
    AVAILABLE = "available"
    UNAVAILABLE = "unavailable"
    Busy= "busy"

# -----REQUEST SCHEMAS----- what clients sends to us
class DonorCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=200, example="John Doe")
    age: int = Field(..., ge=18, le=65, example=30)
    blood_group: BloodGroup = Field(..., example="A+")
    city: str = Field(..., example="Mumbai")
    availability_status: AvailabilityStatus = Field(..., example="available")
    phone: str = Field(..., min_length=10, max_length=10, example=9876543210)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value:str)-> str:
        if not value.isdigit():
            raise ValueError("Phone number must contain only digits")
        if len(value) != 10:
            raise ValueError("Phone number must be exactly 10 digits long")
        return value
    
    @field_validator("name")
    @classmethod
    def validate_name(cls, value:str)-> str:
        if not all(x.isalpha() or x.isspace() for x in value):
            raise ValueError("Name must contain only letters and spaces")
        return value.strip().title()
    
class DonorUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200, example="John Doe")
    age: Optional[int] = Field(None, ge=18, le=65, example=30)
    city: Optional[str] = Field(None, example="Mumbai")
    availability_status: Optional[AvailabilityStatus] = Field(None, example="available")
    phone: Optional[str] = Field(None, min_length=10, max_length=10, example=9876543210)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value:str)-> str:
        if not value.isdigit():
            raise ValueError("Phone number must contain only digits")
        if len(value) != 10:
            raise ValueError("Phone number must be exactly 10 digits long")
        return value
    
    @field_validator("name")
    @classmethod
    def validate_name(cls, value:str)-> str:
        if not all(x.isalpha() or x.isspace() for x in value):
            raise ValueError("Name must contain only letters and spaces")
        return value.strip().title()
    
# -----RESPONSE SCHEMAS----- what we send back to clients
class DonorResponse(BaseModel):
    id: int
    name: str
    age: int
    blood_group: BloodGroup
    city: str
    availability_status: AvailabilityStatus
    phone: str

    model_config = {"from_attributes": True}  

class DonorListResponse(BaseModel):
    total: int
    donors: list[DonorResponse]