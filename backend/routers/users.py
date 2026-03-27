from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.dependencies.auth import (
    get_current_user,
    verify_firebase_token,
    require_admin,
)
from backend.models.user import User
from backend.schemas.user import UserCreate, UserUpdate, UserResponse
import uuid

router = APIRouter(prefix="/users", tags=["Users"])


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
    current_user: User = Depends(get_current_user),  # fully protected
):
    """Get the authenticated user's own profile."""
    return current_user


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


