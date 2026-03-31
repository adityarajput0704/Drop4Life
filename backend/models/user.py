from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from backend.database import Base

class User(Base):
    __tablename__ = "users"

    id              = Column(String, primary_key=True)  # Firebase UID
    firebase_uid    = Column(String, unique=True, nullable=False, index=True)
    email           = Column(String, unique=True, nullable=False, index=True)
    full_name       = Column(String, nullable=False)
    phone           = Column(String, nullable=True)
    blood_group     = Column(String, nullable=True)
    role            = Column(String, default="donor", nullable=False)
    is_active       = Column(Boolean, default=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())

    # One user can have one donor profile
    donor_profile   = relationship("Donor", back_populates="user", uselist=False)