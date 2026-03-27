# app/models/blood_request.py

from sqlalchemy import (
    Column, Integer, String, DateTime,
    Enum as SAEnum, ForeignKey, Text
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base
from backend.models.donor import BloodGroupEnum
import enum


class UrgencyEnum(str, enum.Enum):
    CRITICAL = "critical"
    URGENT   = "urgent"
    NORMAL   = "normal"


class StatusEnum(str, enum.Enum):
    OPEN      = "open"
    FULFILLED = "fulfilled"
    CANCELLED = "cancelled"


class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id                 = Column(Integer, primary_key=True, index=True)
    blood_group_needed = Column(SAEnum(BloodGroupEnum), nullable=False)
    hospital_id        = Column(Integer, ForeignKey("hospitals.id"), nullable=False)
    donor_id           = Column(Integer, ForeignKey("donors.id"), nullable=True)
    patient_name       = Column(String(100), nullable=False)
    contact_phone      = Column(String(20), nullable=False)
    units_needed       = Column(Integer, nullable=False, default=1)
    urgency            = Column(SAEnum(UrgencyEnum), nullable=False)
    status             = Column(
        SAEnum(StatusEnum),
        nullable=False,
        default=StatusEnum.OPEN,
    )
    notes              = Column(Text, nullable=True)
    created_at         = Column(DateTime(timezone=True), server_default=func.now())
    updated_at         = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships — SQLAlchemy loads related objects automatically
    hospital           = relationship("Hospital", back_populates="blood_requests")
    donor              = relationship("Donor", back_populates="donations")

    def __repr__(self):
        return f"<BloodRequest {self.blood_group_needed} @ {self.hospital_id}>"