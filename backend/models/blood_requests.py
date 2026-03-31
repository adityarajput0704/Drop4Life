from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SAEnum, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base
import enum


class UrgencyEnum(str, enum.Enum):
    LOW      = "low"
    MEDIUM   = "medium"
    HIGH     = "high"
    CRITICAL = "critical"


class RequestStatusEnum(str, enum.Enum):
    OPEN      = "open"
    ACCEPTED  = "accepted"
    FULFILLED = "fulfilled"
    CANCELLED = "cancelled"


class BloodGroupEnum(str, enum.Enum):
    A_POS  = "A+"
    A_NEG  = "A-"
    B_POS  = "B+"
    B_NEG  = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS  = "O+"
    O_NEG  = "O-"


class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id              = Column(Integer, primary_key=True, index=True)

    # Hospital that created this request
    hospital_id     = Column(Integer, ForeignKey("hospitals.id"), nullable=False)

    # Donor who accepted (null until accepted)
    donor_id        = Column(Integer, ForeignKey("donors.id"), nullable=True)

    blood_group     = Column(SAEnum(BloodGroupEnum), nullable=False)
    units_needed    = Column(Integer, nullable=False, default=1)
    patient_name    = Column(String(200), nullable=False)
    urgency         = Column(SAEnum(UrgencyEnum), nullable=False, default=UrgencyEnum.MEDIUM)
    status          = Column(
        SAEnum(RequestStatusEnum),
        nullable=False,
        default=RequestStatusEnum.OPEN
    )
    notes           = Column(Text, nullable=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    hospital        = relationship("Hospital", back_populates="blood_requests")
    donor           = relationship("Donor", back_populates="donations")