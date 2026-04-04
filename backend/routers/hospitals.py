from fastapi import APIRouter, Depends, HTTPException, status, Query
from backend.core.pagination import PaginationParams, PagedResponse
from typing import Optional
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.models.hospitals import Hospital
from backend.models.user import User
from backend.schemas.hospital import HospitalCreate, HospitalResponse, HospitalUpdate
from backend.dependencies.auth import verify_firebase_token, get_current_hospital, require_admin

router = APIRouter(prefix="/hospitals", tags=["Hospitals"])


@router.post("/register", response_model=HospitalResponse, status_code=status.HTTP_201_CREATED)
def register_hospital(
    data: HospitalCreate,
    decoded_token: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db),
):
    """
    Hospital registers using their Firebase token.
    Auto-approved on registration.
    Admin can revoke later.
    """
    firebase_uid = decoded_token.get("uid")
    firebase_email = decoded_token.get("email")

    # Prevent duplicate registration
    existing = db.query(Hospital).filter(
        Hospital.firebase_uid == firebase_uid
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Hospital already registered.",
        )

    # Prevent duplicate registration number
    reg_taken = db.query(Hospital).filter(
        Hospital.registration_no == data.registration_no
    ).first()
    if reg_taken:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This registration number is already in use.",
        )

    hospital = Hospital(
        firebase_uid    = firebase_uid,
        email           = firebase_email,
        name            = data.name,
        phone           = data.phone,
        address         = data.address,
        city            = data.city,
        registration_no = data.registration_no,
        is_verified     = True,   # auto-approved
    )

    db.add(hospital)
    db.commit()
    db.refresh(hospital)
    return hospital


@router.get("/me", response_model=HospitalResponse)
def get_my_hospital_profile(
    current_hospital: Hospital = Depends(get_current_hospital),
):
    """Get the authenticated hospital's profile."""
    return current_hospital

@router.patch("/me", response_model=HospitalResponse)
def update_my_hospital_profile(
    updates:          HospitalUpdate,
    current_hospital: Hospital = Depends(get_current_hospital),
    db:               Session = Depends(get_db),
):
    """
    Hospital updates their own profile.
    Registration number cannot be changed — excluded from schema.
    Verification status cannot be changed — only admin controls that.
    """
    for field, value in updates.model_dump(exclude_unset=True).items():
        setattr(current_hospital, field, value)

    db.commit()
    db.refresh(current_hospital)
    return current_hospital


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_my_hospital(
    current_hospital: Hospital = Depends(get_current_hospital),
    db:               Session = Depends(get_db),
):
    """
    Hospital deactivates their own account.
    We soft delete — set is_active=False, never hard delete.
    All their existing blood requests remain in the system for audit trail.
    """
    current_hospital.is_active = False
    db.commit()

# ── ADMIN ONLY ────────────────────────────────────────────────────────────────

@router.get("/", response_model=dict)
@router.get("/", response_model=PagedResponse[HospitalResponse])
def list_hospitals(
    pagination: PaginationParams = Depends(),
    search:     Optional[str]    = Query(None),
    admin:      User             = Depends(require_admin),
    db:         Session          = Depends(get_db),
):
    """Admin only — list all hospitals with pagination and search."""
    query = db.query(Hospital)

    if search:
        query = query.filter(
            Hospital.name.ilike(f"%{search}%") |
            Hospital.city.ilike(f"%{search}%")
        )

    total = query.count()
    items = (
        query
        .order_by(Hospital.created_at.desc())
        .offset(pagination.offset)
        .limit(pagination.page_size)
        .all()
    )

    return PagedResponse.create(
        items=[HospitalResponse.model_validate(h) for h in items],
        total=total,
        params=pagination,
    )


@router.patch("/{hospital_id}/revoke", response_model=HospitalResponse)
def revoke_hospital(
    hospital_id: int,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Admin only — revoke a hospital's verified status."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found.")

    hospital.is_verified = False
    db.commit()
    db.refresh(hospital)
    return hospital


@router.patch("/{hospital_id}/verify", response_model=HospitalResponse)
def verify_hospital(
    hospital_id: int,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Admin only — re-verify a previously revoked hospital."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found.")

    hospital.is_verified = True
    db.commit()
    db.refresh(hospital)
    return hospital