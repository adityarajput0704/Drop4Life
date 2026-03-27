from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth as firebase_auth
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.models.user import User

# This tells FastAPI to expect: Authorization: Bearer <token>
bearer_scheme = HTTPBearer()


def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """
    Verifies the Firebase JWT token from the Authorization header.
    Returns the decoded token payload if valid.
    Raises 401 if invalid or expired.
    """
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
    """
    Gets the current user from the database using the Firebase UID.
    This syncs Firebase auth with your own user records.
    """
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


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependency for admin-only routes.
    Reuses get_current_user — no duplicate logic.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )
    return current_user
