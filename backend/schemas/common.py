from pydantic import BaseModel


class SuccessResponse(BaseModel):
    """Standard success message response"""
    message: str
    success: bool = True