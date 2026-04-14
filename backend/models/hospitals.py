from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base

class Hospital(Base):
    __tablename__ = "hospitals"

    id              = Column(Integer, primary_key=True, index=True)
    firebase_uid    = Column(String, unique=True, nullable=False, index=True)
    email           = Column(String, unique=True, nullable=False, index=True)
    name            = Column(String(200), nullable=False)
    phone           = Column(String(20), nullable=False)
    address         = Column(String(300), nullable=False)
    city            = Column(String(100), nullable=False)
    registration_no = Column(String(100), unique=True, nullable=False)
    is_verified     = Column(Boolean, default=True, nullable=False)
    is_active       = Column(Boolean, default=True, nullable=False)

    # Geocoded from address on registration — free via Nominatim
    latitude        = Column(Float, nullable=True)
    longitude       = Column(Float, nullable=True)

    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())

    blood_requests  = relationship("BloodRequest", back_populates="hospital")

    def __repr__(self):
        return f"<Hospital {self.name} ({self.city})>"