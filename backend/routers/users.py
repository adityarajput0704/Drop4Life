from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.dependencies.auth import (
    get_current_user,
    verify_firebase_token,
    require_admin,
)
from backend.models.user import User
from backend.models.hospitals import Hospital
from backend.schemas.user import UserCreate, UserUpdate, UserResponse
import uuid
from pydantic import BaseModel

router = APIRouter(prefix="/users", tags=["Users"])
class FCMTokenUpdate(BaseModel):
    fcm_token: str

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(
    user_data: UserCreate,
    decoded_token: dict = Depends(verify_firebase_token),  # verify token but don't require DB user yet
    db: Session = Depends(get_db),
):
    """
    Called AFTER Firebase signup on the frontend.
    Creates the user record in our database using the Firebase UID.
    This is the bridge between Firebase and your system.
    """
    firebase_uid = decoded_token.get("uid")
    firebase_email = decoded_token.get("email")

    # Check if user already registered
    existing = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already registered.",
        )

    # Email from token is authoritative — don't trust the request body for email
    user = User(
        id=firebase_uid,
        firebase_uid=firebase_uid,
        email=firebase_email or user_data.email,
        full_name=user_data.full_name,
        phone=user_data.phone,
        blood_group=user_data.blood_group,
    )

    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/me", response_model=UserResponse)
def get_my_profile(
    decoded_token: dict = Depends(verify_firebase_token),  # ← changed dependency
    db: Session = Depends(get_db),                         # ← added db
):
    """
    Unified identity endpoint — checks users table first, then hospitals.
    Frontend always calls this after login to get role + profile.
    Returns a consistent UserResponse shape regardless of account type.
    """
    uid = decoded_token.get("uid")

    # 1. Check users table (admin, donor roles)
    user = db.query(User).filter(User.firebase_uid == uid).first()
    if user:
        return user

    # 2. Check hospitals table — map to UserResponse shape
    hospital = db.query(Hospital).filter(Hospital.firebase_uid == uid).first()
    if hospital:
        return UserResponse(
            id=str(hospital.id),
            firebase_uid=hospital.firebase_uid,
            email=hospital.email,
            full_name=hospital.name,       # hospitals use `name` not `full_name`
            phone=hospital.phone,
            blood_group=None,              # hospitals don't have blood group
            role="hospital",              # hardcoded — hospitals table = hospital role
            is_active=hospital.is_active,
            created_at=hospital.created_at,

            city=hospital.city,
            is_verified=hospital.is_verified,
            hospital_name=hospital.name,
        )

    # 3. Firebase token valid but no DB record — not registered yet
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="User not registered. Please complete registration.",
    )

@router.patch("/me", response_model=UserResponse)
def update_my_profile(
    updates: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the authenticated user's own profile."""
    for field, value in updates.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/", response_model=list[UserResponse])
def list_all_users(
    admin: User = Depends(require_admin),  # admin only
    db: Session = Depends(get_db),
):
    """Admin-only: list all registered users."""
    return db.query(User).filter(User.is_active == True).all()


@router.patch("/{user_id}/deactivate", response_model=UserResponse)
def deactivate_user(
    user_id: str,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Admin-only: deactivate a user account."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    user.is_active = False
    db.commit()
    db.refresh(user)
    return user




@router.post("/fcm-token", status_code=200)
def save_fcm_token(
    data: FCMTokenUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Flutter calls this on app start after getting the FCM token.
    Saves the device token so backend can send push notifications.
    """
    current_user.fcm_token = data.fcm_token
    db.commit()
    return {"message": "FCM token saved successfully"}


