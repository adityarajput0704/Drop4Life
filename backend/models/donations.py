from sqlalchemy import Column, String, DateTime, ForeignKey
from backend.database import Base
import uuid

class Donation(Base):
    __tablename__ = "donations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    donor_id = Column(String, ForeignKey("users.id"), nullable=False)
    request_id = Column(String, ForeignKey("blood_requests.id"), nullable=False)

    status = Column(String, default="pending")  # pending / completed / rejected

    donation_date = Column(DateTime, nullable=True)

