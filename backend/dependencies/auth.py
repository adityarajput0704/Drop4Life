from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth as firebase_auth
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.models.user import User
from backend.models.hospitals import Hospital

bearer_scheme = HTTPBearer()


def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """Verifies Firebase JWT. Returns decoded token payload."""
    token = credentials.credentials
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please login again.",
        )
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials.",
        )


def get_current_user(
    decoded_token: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db),
) -> User:
    """Looks up a User by Firebase UID."""
    firebase_uid = decoded_token.get("uid")
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please complete registration.",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated.",
        )
    return user


def get_current_hospital(
    decoded_token: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db),
) -> Hospital:
    """
    Looks up a Hospital by Firebase UID.
    Separate from get_current_user — hospitals are a different entity.
    """
    firebase_uid = decoded_token.get("uid")
    hospital = db.query(Hospital).filter(
        Hospital.firebase_uid == firebase_uid
    ).first()

    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found. Please complete registration.",
        )
    if not hospital.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hospital account is deactivated.",
        )
    if not hospital.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hospital is not verified. Contact admin.",
        )
    return hospital


def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Admin-only routes."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )
    return current_user