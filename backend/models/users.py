from sqlalchemy import Column, String, Boolean, Float, DateTime
from backend.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)  # Firebase UID
    name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    role = Column(String, nullable=False)  # donor / requester / hospital

    blood_group = Column(String, nullable=True)

    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    is_available = Column(Boolean, default=True)
    last_donation_date = Column(DateTime, nullable=True)

