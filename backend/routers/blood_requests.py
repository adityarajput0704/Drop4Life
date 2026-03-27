# app/routers/blood_requests.py

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy.orm import Session, joinedload
from typing import Optional

from backend.dependencies import get_db
from backend.models.blood_requests import BloodRequest, UrgencyEnum, StatusEnum
from backend.models.hospitals import Hospital
from backend.models.donor import Donor
from backend.schemas.blood_request import (
    BloodRequestCreate,
    BloodRequestUpdate,
    BloodRequestResponse,
    BloodRequestListResponse,
    UrgencyLevel,
)
from backend.schemas.donor import BloodGroup

router = APIRouter(prefix="/blood-requests", tags=["Blood Requests"])


@router.get("", response_model=BloodRequestListResponse)
def get_blood_requests(
    city:        Optional[str]        = Query(None, description="Filter by hospital city"),
    blood_group: Optional[BloodGroup] = Query(None, description="Filter by blood group needed"),
    urgency:     Optional[UrgencyLevel] = Query(None, description="Filter by urgency"),
    status:      Optional[str]        = Query("open", description="Filter by status"),
    db:          Session              = Depends(get_db),
):
    """
    List blood requests with optional filters.

    joinedload tells SQLAlchemy to fetch hospital and donor
    in the SAME query using a SQL JOIN — not separate queries.

    Without joinedload: 1 query for requests + N queries for hospitals
    = N+1 problem (kills performance at scale)
    With joinedload: always exactly 1 query, regardless of result size.
    """
    query = (
        db.query(BloodRequest)
        .options(
            joinedload(BloodRequest.hospital),  # JOIN hospitals table
            joinedload(BloodRequest.donor),     # JOIN donors table
        )
    )

    filters_applied = {}

    if blood_group:
        query = query.filter(BloodRequest.blood_group_needed == blood_group.value)
        filters_applied["blood_group"] = blood_group

    if urgency:
        query = query.filter(BloodRequest.urgency == urgency.value)
        filters_applied["urgency"] = urgency

    if status:
        query = query.filter(BloodRequest.status == status)
        filters_applied["status"] = status

    # Filter by hospital city — this queries ACROSS tables
    if city:
        query = query.join(BloodRequest.hospital).filter(
            Hospital.city.ilike(f"%{city}%")
        )
        filters_applied["city"] = city

    requests = query.all()

    return BloodRequestListResponse(
        total_found=len(requests),
        filters_applied=filters_applied,
        requests=requests,
    )


@router.get("/{request_id}", response_model=BloodRequestResponse)
def get_blood_request(request_id: int, db: Session = Depends(get_db)):
    request = (
        db.query(BloodRequest)
        .options(
            joinedload(BloodRequest.hospital),
            joinedload(BloodRequest.donor),
        )
        .filter(BloodRequest.id == request_id)
        .first()
    )

    if request is None:
        raise HTTPException(
            status_code=404,
            detail=f"Blood request {request_id} not found",
        )

    return request


@router.post("/create", response_model=BloodRequestResponse, status_code=201)
def create_blood_request(request_data: BloodRequestCreate, db: Session = Depends(get_db)):
    # Verify hospital exists before creating request against it
    hospital = db.query(Hospital).filter(
        Hospital.id == request_data.hospital_id,
        Hospital.is_active == True,
    ).first()

    if hospital is None:
        raise HTTPException(
            status_code=404,
            detail=f"Hospital {request_data.hospital_id} not found",
        )

    new_request = BloodRequest(
        blood_group_needed=request_data.blood_group_needed.value,
        hospital_id=request_data.hospital_id,
        patient_name=request_data.patient_name,
        contact_phone=request_data.contact_phone,
        units_needed=request_data.units_needed,
        urgency=request_data.urgency.value,
        notes=request_data.notes,
        status=StatusEnum.OPEN,
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    # After refresh, relationships aren't auto-loaded — fetch with joinedload
    return (
        db.query(BloodRequest)
        .options(
            joinedload(BloodRequest.hospital),
            joinedload(BloodRequest.donor),
        )
        .filter(BloodRequest.id == new_request.id)
        .first()
    )


@router.patch("/{request_id}", response_model=BloodRequestResponse)
def update_blood_request(
    request_id: int,
    updates: BloodRequestUpdate,
    db: Session = Depends(get_db),
):
    request = db.query(BloodRequest).filter(
        BloodRequest.id == request_id
    ).first()

    if request is None:
        raise HTTPException(status_code=404, detail=f"Request {request_id} not found")

    update_data = updates.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        if hasattr(value, "value"):
            value = value.value
        setattr(request, field, value)

    db.commit()
    db.refresh(request)

    return (
        db.query(BloodRequest)
        .options(
            joinedload(BloodRequest.hospital),
            joinedload(BloodRequest.donor),
        )
        .filter(BloodRequest.id == request_id)
        .first()
    )


@router.patch("/{request_id}/assign-donor", response_model=BloodRequestResponse)
def assign_donor_to_request(
    request_id: int,
    donor_id:   int = Query(..., description="ID of donor to assign"),
    db:         Session = Depends(get_db),
):
    """
    Assign a matching donor to an open blood request.
    Validates:
    - Request must be OPEN
    - Donor must exist and be AVAILABLE
    - Donor blood group must match request
    """
    blood_request = db.query(BloodRequest).filter(
        BloodRequest.id == request_id
    ).first()

    if blood_request is None:
        raise HTTPException(status_code=404, detail="Blood request not found")

    if blood_request.status != StatusEnum.OPEN:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot assign donor — request is already {blood_request.status}",
        )

    donor = db.query(Donor).filter(
        Donor.id == donor_id,
        Donor.is_active == True,
    ).first()

    if donor is None:
        raise HTTPException(status_code=404, detail="Donor not found")

    # Blood group compatibility check
    if donor.blood_group != blood_request.blood_group_needed:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Blood group mismatch — request needs "
                f"{blood_request.blood_group_needed}, "
                f"donor has {donor.blood_group}"
            ),
        )

    # Assign donor and mark request fulfilled
    blood_request.donor_id = donor_id
    blood_request.status   = StatusEnum.FULFILLED

    db.commit()
    db.refresh(blood_request)

    return (
        db.query(BloodRequest)
        .options(
            joinedload(BloodRequest.hospital),
            joinedload(BloodRequest.donor),
        )
        .filter(BloodRequest.id == request_id)
        .first()
    )