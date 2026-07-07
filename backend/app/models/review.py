from sqlalchemy import Column, String, Integer, Boolean, DateTime, JSON, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class Review(Base):
    __tablename__ = "reviews"

    id = Column(String, primary_key=True, index=True)
    product_id = Column(String, index=True, nullable=False)
    seller_id = Column(String, index=True, nullable=False)
    user_id = Column(String, index=True, nullable=False)  # Firebase UID
    user_name = Column(String, nullable=False)
    user_photo = Column(String, nullable=True)
    rating = Column(Integer, nullable=False)  # 1-5
    comment = Column(Text, nullable=False)
    photos = Column(JSON, default=[])  # URLs stored in Firebase Storage

    # Moderation
    is_approved = Column(Boolean, default=False, index=True)
    is_flagged = Column(Boolean, default=False)
    flag_reason = Column(String, nullable=True)
    flagged_at = Column(DateTime, nullable=True)

    # Engagement
    helpful_count = Column(Integer, default=0)
    report_count = Column(Integer, default=0)

    # Seller Response
    seller_response = Column(Text, nullable=True)
    seller_response_date = Column(DateTime, nullable=True)

    is_verified_purchase = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, nullable=True)
