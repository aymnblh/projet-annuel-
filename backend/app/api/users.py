from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, UserUpdate
from typing import List
from datetime import datetime

router = APIRouter()

@router.post("/sync", response_model=UserResponse)
def sync_user(data: UserCreate, db: Session = Depends(get_db)):
    """Called from Flutter after Firebase Auth login to sync user profile."""
    user = db.query(User).filter(User.uid == data.uid).first()
    if not user:
        user = User(**data.model_dump(), created_at=datetime.utcnow())
        db.add(user)
    else:
        user.last_login = datetime.utcnow()
        if data.name:
            user.name = data.name
        if data.photo_url:
            user.photo_url = data.photo_url
    db.commit()
    db.refresh(user)
    return user

@router.get("/{uid}", response_model=UserResponse)
def get_user(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.put("/{uid}", response_model=UserResponse)
def update_user(uid: str, data: UserUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    for key, value in data.model_dump(exclude_none=True).items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user

@router.get("/", response_model=List[UserResponse])
def list_users(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    return db.query(User).offset(skip).limit(limit).all()

@router.put("/{uid}/ban")
def toggle_ban(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_banned = not user.is_banned
    db.commit()
    return {"uid": uid, "is_banned": user.is_banned}
