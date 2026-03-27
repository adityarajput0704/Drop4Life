# app/routers/donors.py

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional

from backend.dependencies.__init__ import get_db
from backend.models.donor import Donor, BloodGroupEnum, AvailabilityEnum
from backend.schemas.donor import (
    DonorCreate, DonorUpdate, DonorResponse,
    DonorListResponse, BloodGroup, AvailabilityStatus,
)

router = APIRouter(prefix="/donors", tags=["Donors"])


@router.get("/search", response_model=DonorListResponse)
def search_donors(
    blood_group:  BloodGroup                    = Query(...),
    city:         Optional[str]                 = Query(None),
    availability: Optional[AvailabilityStatus]  = Query(None),
    db:           Session                       = Depends(get_db),  # ← injected session
):
    """Search donors by blood group with optional filters."""

    # Build query — SQLAlchemy doesn't hit DB until .all() or .first()
    query = db.query(Donor).filter(
        Donor.blood_group == blood_group.value,
        Donor.is_active == True,
    )

    # Chain filters conditionally — only applied if parameter was sent
    if city:
        query = query.filter(Donor.city.ilike(f"%{city}%"))  # ilike = case-insensitive LIKE
    if availability:
        query = query.filter(Donor.availability == availability.value)

    donors = query.all()  # ← SQL executes HERE, returns list of Donor model instances

    return DonorListResponse(total_found=len(donors), donors=donors)


@router.get("/{donor_id}", response_model=DonorResponse)
def get_donor_by_id(donor_id: int, db: Session = Depends(get_db)):
    """Get single donor by ID."""
    donor = db.query(Donor).filter(
        Donor.id == donor_id,
        Donor.is_active == True,
    ).first()  # .first() returns None if not found, never raises

    if donor is None:
        raise HTTPException(status_code=404, detail=f"Donor {donor_id} not found")

    return donor  # Pydantic's from_attributes=True converts model → schema


@router.post("/register", response_model=DonorResponse, status_code=201)
def register_donor(donor_data: DonorCreate, db: Session = Depends(get_db)):
    """Register a new donor."""

    # Check uniqueness before inserting
    existing = db.query(Donor).filter(
        or_(
            Donor.phone == donor_data.phone,
            Donor.email == donor_data.email,
        )
    ).first()

    if existing:
        raise HTTPException(
            status_code=409,  # 409 Conflict — resource already exists
            detail="A donor with this phone or email already exists",
        )

    # Create model instance — not saved yet
    new_donor = Donor(
        name=donor_data.name,
        blood_group=donor_data.blood_group.value,
        city=donor_data.city,
        age=donor_data.age,
        phone=donor_data.phone,
        availability=donor_data.availability.value,
    )

    db.add(new_donor)      # stage the insert
    db.commit()            # write to PostgreSQL
    db.refresh(new_donor)  # reload from DB — gets generated id, created_at

    return new_donor


@router.patch("/{donor_id}", response_model=DonorResponse)
def update_donor(donor_id: int, updates: DonorUpdate, db: Session = Depends(get_db)):
    """Partially update donor profile."""
    donor = db.query(Donor).filter(Donor.id == donor_id).first()

    if donor is None:
        raise HTTPException(status_code=404, detail=f"Donor {donor_id} not found")

    # exclude_unset=True → only fields the client actually sent
    update_data = updates.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        # Handle enum values — store the .value string, not the enum object
        if hasattr(value, "value"):
            value = value.value
        setattr(donor, field, value)  # dynamically update each field

    db.commit()
    db.refresh(donor)

    return donor


@router.delete("/{donor_id}", status_code=204)
def delete_donor(donor_id: int, db: Session = Depends(get_db)):
    """
    Soft delete — sets is_active=False, never removes from DB.
    WHY soft delete: you need audit trails, data recovery, and referential integrity.
    Hard delete breaks foreign keys and loses history.
    """
    donor = db.query(Donor).filter(Donor.id == donor_id).first()

    if donor is None:
        raise HTTPException(status_code=404, detail=f"Donor {donor_id} not found")

    donor.is_active = False
    db.commit()

    # 204 No Content — success, nothing to return