# app/routers/hospitals.py

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy.orm import Session
from typing import Optional

from backend.dependencies.__init__ import get_db
from backend.models.hospitals import Hospital
from backend.schemas.hospital import (
    HospitalCreate,
    HospitalUpdate,
    HospitalResponse,
    HospitalListResponse,
)

router = APIRouter(prefix="/hospitals", tags=["Hospitals"])


@router.get("", response_model=HospitalListResponse)
def get_hospitals(
    city:     Optional[str]  = Query(None, description="Filter by city"),
    verified: Optional[bool] = Query(None, description="Filter by verification status"),
    db:       Session        = Depends(get_db),
):
    query = db.query(Hospital).filter(Hospital.is_active == True)

    filters_applied = {}

    if city is not None:
        query = query.filter(Hospital.city.ilike(f"%{city}%"))
        filters_applied["city"] = city

    if verified is not None:
        query = query.filter(Hospital.verified == verified)
        filters_applied["verified"] = verified

    hospitals = query.all()

    return HospitalListResponse(
        total=len(hospitals),
        filters_applied=filters_applied,
        hospitals=hospitals,
    )


@router.get("/{hospital_id}", response_model=HospitalResponse)
def get_hospital_by_id(hospital_id: int, db: Session = Depends(get_db)):
    hospital = db.query(Hospital).filter(
        Hospital.id == hospital_id,
        Hospital.is_active == True,
    ).first()

    if hospital is None:
        raise HTTPException(
            status_code=404,
            detail=f"Hospital with id {hospital_id} not found",
        )

    return hospital


@router.post("/register", response_model=HospitalResponse, status_code=201)
def register_hospital(hospital_data: HospitalCreate, db: Session = Depends(get_db)):
    # Check duplicate email — hospitals must have unique emails
    if hospital_data.email:
        existing = db.query(Hospital).filter(
            Hospital.email == hospital_data.email
        ).first()
        if existing:
            raise HTTPException(
                status_code=409,
                detail="A hospital with this email already exists",
            )

    new_hospital = Hospital(
        name=hospital_data.name,
        address=hospital_data.address,
        city=hospital_data.city,
        phone=hospital_data.phone,
        email=hospital_data.email,
        verified=hospital_data.verified,
        blood_inventory=hospital_data.blood_inventory or {},
    )

    db.add(new_hospital)
    db.commit()
    db.refresh(new_hospital)

    return new_hospital


@router.patch("/{hospital_id}", response_model=HospitalResponse)
def update_hospital(
    hospital_id: int,
    updates: HospitalUpdate,
    db: Session = Depends(get_db),
):
    hospital = db.query(Hospital).filter(
        Hospital.id == hospital_id,
        Hospital.is_active == True,
    ).first()

    if hospital is None:
        raise HTTPException(
            status_code=404,
            detail=f"Hospital with id {hospital_id} not found",
        )

    update_data = updates.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(hospital, field, value)

    db.commit()
    db.refresh(hospital)

    return hospital


@router.delete("/{hospital_id}", status_code=204)
def delete_hospital(hospital_id: int, db: Session = Depends(get_db)):
    hospital = db.query(Hospital).filter(
        Hospital.id == hospital_id,
        Hospital.is_active == True,
    ).first()

    if hospital is None:
        raise HTTPException(
            status_code=404,
            detail=f"Hospital with id {hospital_id} not found",
        )

    hospital.is_active = False
    db.commit()