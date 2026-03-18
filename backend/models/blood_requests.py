from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey
from backend.database import Base
import uuid

class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    created_by = Column(String, ForeignKey("users.id"), nullable=False)

    blood_group = Column(String, nullable=False)
    units_required = Column(Integer, nullable=False)

    hospital_name = Column(String, nullable=False)

    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    urgency = Column(String, nullable=False)  # critical / high / normal
    status = Column(String, default="active")  # active / fulfilled / cancelled

