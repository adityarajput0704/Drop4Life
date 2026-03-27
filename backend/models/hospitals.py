# app/models/hospital.py

from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base


class Hospital(Base):
    __tablename__ = "hospitals"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String(200), nullable=False)
    address         = Column(String(500), nullable=False)
    city            = Column(String(100), nullable=False, index=True)  # index=True: fast city lookups
    phone           = Column(String(20), nullable=False)
    email           = Column(String(255), unique=True, nullable=True)
    verified        = Column(Boolean, default=False, nullable=False)

    # JSON column: stores {"A+": 10, "O-": 5} directly in PostgreSQL
    # Flexible — no need for a separate inventory table at this stage
    blood_inventory = Column(JSON, default=dict)

    is_active       = Column(Boolean, default=True, nullable=False)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())

    # One hospital can have many blood requests posted against it
    blood_requests  = relationship("BloodRequest", back_populates="hospital")

    def __repr__(self):
        return f"<Hospital {self.name} ({self.city})>"