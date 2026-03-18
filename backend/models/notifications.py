from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from backend.database import Base
import uuid

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    title = Column(String, nullable=False)
    message = Column(String, nullable=False)

    type = Column(String)  # request / alert / system

    is_read = Column(Boolean, default=False)

