from sqlalchemy import Column, String, Float, Boolean, Integer, DateTime, JSON, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class Product(Base):
    __tablename__ = "products"

    id = Column(String, primary_key=True, index=True)
    seller_id = Column(String, index=True, nullable=False)  # Firebase UID
    title = Column(String, nullable=False, index=True)
    description = Column(Text)
    price = Column(Float, nullable=False, index=True)
    category = Column(String, index=True)
    wilaya = Column(String, index=True)
    commune = Column(String)
    phone = Column(String)

    # Media
    image_urls = Column(JSON, default=[])
    video_urls = Column(JSON, default=[])

    # Car details
    sub_category = Column(String)
    brand = Column(String, index=True)
    model = Column(String, index=True)
    year = Column(String, index=True)
    km = Column(String)
    fuel = Column(String, index=True)
    gearbox = Column(String)
    engine = Column(String)
    color = Column(String)
    papers = Column(String)
    exchange = Column(Boolean, default=False)

    # Status
    is_sold = Column(Boolean, default=False, index=True)
    is_approved = Column(Boolean, default=False, index=True)
    is_boosted = Column(Boolean, default=False)
    boost_expires_at = Column(DateTime, nullable=True)
    is_urgent = Column(Boolean, default=False)

    # Stats
    view_count = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)
    review_count = Column(Integer, default=0)
    rating_distribution = Column(JSON, default={"1": 0, "2": 0, "3": 0, "4": 0, "5": 0})

    # Extra
    specs = Column(JSON, default={})
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
