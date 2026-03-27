from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.sql import func
import enum
from backend.database import Base


class UserRole(str, enum.Enum):
    admin = "admin"
    donor = "donor"
    recipient = "recipient"


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True)  # Use Firebase UID as primary key
    firebase_uid = Column(String, unique=True, nullable=False, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    role = Column(String, default=UserRole.donor, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())