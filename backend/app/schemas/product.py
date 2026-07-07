from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

class ProductBase(BaseModel):
    title: str
    description: Optional[str] = None
    price: float
    category: Optional[str] = None
    wilaya: Optional[str] = None
    commune: Optional[str] = None
    phone: Optional[str] = None
    image_urls: List[str] = []
    video_urls: List[str] = []
    sub_category: Optional[str] = None
    brand: Optional[str] = None
    model: Optional[str] = None
    year: Optional[str] = None
    km: Optional[str] = None
    fuel: Optional[str] = None
    gearbox: Optional[str] = None
    engine: Optional[str] = None
    color: Optional[str] = None
    papers: Optional[str] = None
    exchange: bool = False
    is_urgent: bool = False
    specs: Dict[str, Any] = {}

class ProductCreate(ProductBase):
    seller_id: str  # Firebase UID

class ProductUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    is_sold: Optional[bool] = None
    is_approved: Optional[bool] = None

class ProductResponse(ProductBase):
    id: str
    seller_id: str
    is_sold: bool = False
    is_approved: bool = False
    is_boosted: bool = False
    is_urgent: bool = False
    view_count: int = 0
    average_rating: float = 0.0
    review_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True
