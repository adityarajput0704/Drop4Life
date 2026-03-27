# app/models/donor.py

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base
import enum


# Mirror your Pydantic enums as Python enums for SQLAlchemy
# These become CHECK constraints in PostgreSQL automatically
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
    # __tablename__ = the actual table name in PostgreSQL
    __tablename__ = "donors"

    # Column() defines each column: type, constraints
    id           = Column(Integer, primary_key=True, index=True)
    name         = Column(String(100), nullable=False)
    blood_group  = Column(SAEnum(BloodGroupEnum), nullable=False)
    city         = Column(String(100), nullable=False)
    age          = Column(Integer, nullable=False)
    phone        = Column(String(20), nullable=False, unique=True)
    email        = Column(String(255), unique=True, nullable=True)
    availability = Column(
        SAEnum(AvailabilityEnum),
        nullable=False,
        default=AvailabilityEnum.AVAILABLE,
    )
    is_active    = Column(Boolean, default=True, nullable=False)

    # server_default=func.now() → PostgreSQL sets this, not Python.
    # Safer: works even if you insert via raw SQL directly.
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationship: one donor can fulfill many blood requests
    # back_populates connects both sides — defined after BloodRequest model exists
    donations    = relationship("BloodRequest", back_populates="donor")

    def __repr__(self):
        return f"<Donor {self.name} ({self.blood_group})>"