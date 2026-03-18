from sqlalchemy import Column, String, Float, DateTime
from backend.database import Base
from datetime import datetime
import uuid

class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    name = Column(String, nullable=False)
    address = Column(String, nullable=False)

    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    contact_number = Column(String, nullable=False)

