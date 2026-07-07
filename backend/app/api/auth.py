from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse
from datetime import datetime
from typing import Optional
import firebase_admin
from firebase_admin import credentials, auth
import os

# Initialize Firebase Admin SDK (for verifying tokens on the server side)
# Only needed if you want the backend to verify Firebase tokens
# Download your service account key from Firebase Console -> Project Settings -> Service Accounts
# and point to it via env var FIREBASE_SERVICE_ACCOUNT
_firebase_initialized = False
def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized:
        sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT")
        if sa_path and os.path.exists(sa_path):
            cred = credentials.Certificate(sa_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True

router = APIRouter()

async def verify_firebase_token(authorization: Optional[str] = Header(None)):
    """
    Middleware dependency that verifies the Firebase ID token from the Authorization header.
    Flutter app should send: Authorization: Bearer <firebase_id_token>
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
    token = authorization.split(" ")[1]
    try:
        _init_firebase()
        decoded = auth.verify_id_token(token)
        return decoded
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {str(e)}")

@router.post("/sync", response_model=UserResponse)
async def sync_firebase_user(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    """
    Called after Firebase login in the Flutter app.
    Verifies the Firebase token and syncs the user profile to PostgreSQL.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    token = authorization.split(" ")[1]
    try:
        _init_firebase()
        firebase_user = auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")

    uid = firebase_user["uid"]
    user = db.query(User).filter(User.uid == uid).first()
    now = datetime.utcnow()

    if not user:
        user = User(
            uid=uid,
            name=firebase_user.get("name", ""),
            email=firebase_user.get("email", ""),
            photo_url=firebase_user.get("picture"),
            created_at=now,
            last_login=now,
        )
        db.add(user)
    else:
        user.last_login = now
        if firebase_user.get("name"):
            user.name = firebase_user["name"]
        if firebase_user.get("picture"):
            user.photo_url = firebase_user["picture"]

    db.commit()
    db.refresh(user)
    return user

@router.get("/me", response_model=UserResponse)
async def get_me(
    token_data: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """Returns the current authenticated user's profile from PostgreSQL."""
    user = db.query(User).filter(User.uid == token_data["uid"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found. Call /auth/sync first.")
    return user
