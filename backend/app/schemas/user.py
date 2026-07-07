from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime

class UserCreate(BaseModel):
    uid: str  # Firebase UID
    name: str
    email: str
    phone: Optional[str] = None
    photo_url: Optional[str] = None

class UserResponse(BaseModel):
    uid: str
    name: str
    email: str
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    whatsapp: Optional[str] = None
    is_admin: bool = False
    is_banned: bool = False
    is_pro: bool = False
    is_verified: bool = False
    rating: Dict[str, Any] = {"average": 0.0, "count": 0}
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    whatsapp: Optional[str] = None
    is_banned: Optional[bool] = None
    is_pro: Optional[bool] = None
    is_verified: Optional[bool] = None
