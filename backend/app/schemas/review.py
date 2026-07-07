from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ReviewCreate(BaseModel):
    product_id: str
    seller_id: str
    user_id: str
    user_name: str
    user_photo: Optional[str] = None
    rating: int
    comment: str
    photos: List[str] = []

class ReviewResponse(BaseModel):
    id: str
    product_id: str
    seller_id: str
    user_id: str
    user_name: str
    user_photo: Optional[str] = None
    rating: int
    comment: str
    photos: List[str] = []
    is_approved: bool = False
    is_flagged: bool = False
    helpful_count: int = 0
    seller_response: Optional[str] = None
    seller_response_date: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ReviewUpdate(BaseModel):
    is_approved: Optional[bool] = None
    is_flagged: Optional[bool] = None
    flag_reason: Optional[str] = None
    seller_response: Optional[str] = None
