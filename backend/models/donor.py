from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SAEnum, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base
import enum

class BloodGroupEnum(str, enum.Enum):
    A_POS  = "A+"
    A_NEG  = "A-"
    B_POS  = "B+"
    B_NEG  = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS  = "O+"
    O_NEG  = "O-"

class AvailabilityEnum(str, enum.Enum):
    AVAILABLE   = "available"
    UNAVAILABLE = "unavailable"
    BUSY        = "busy"

class Donor(Base):
    __tablename__ = "donors"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(String, ForeignKey("users.id"), unique=True, nullable=False)

    # Donor-specific fields only — no name, email, phone (those live on User)
    blood_group  = Column(SAEnum(BloodGroupEnum), nullable=False)
    city         = Column(String(100), nullable=False)
    age          = Column(Integer, nullable=False)
    availability = Column(
        SAEnum(AvailabilityEnum),
        nullable=False,
        default=AvailabilityEnum.AVAILABLE,
    )
    is_active    = Column(Boolean, default=True, nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), onupdate=func.now())

    user         = relationship("User", back_populates="donor_profile")
    donations    = relationship("BloodRequest", back_populates="donor")

    def __repr__(self):
        return f"<Donor {self.user_id} ({self.blood_group})>"