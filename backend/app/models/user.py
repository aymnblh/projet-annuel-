from sqlalchemy import Column, String, Boolean, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    uid = Column(String, primary_key=True, index=True)  # Firebase UID
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True)
    phone = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    cover_image_url = Column(String, nullable=True)
    whatsapp = Column(String, nullable=True)

    # Status
    is_admin = Column(Boolean, default=False)
    is_banned = Column(Boolean, default=False, index=True)
    is_pro = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=False)

    # Rating (as seller)
    rating = Column(JSON, default={"average": 0.0, "count": 0})

    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
