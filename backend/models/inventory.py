from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from backend.database import Base
from datetime import datetime
import uuid

class BloodInventory(Base):
    __tablename__ = "blood_inventory"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    hospital_id = Column(String, ForeignKey("hospitals.id"), nullable=False)

    blood_group = Column(String, nullable=False)
    units_available = Column(Integer, default=0)

    last_updated = Column(DateTime, default=datetime.utcnow)