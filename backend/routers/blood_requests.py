from fastapi import APIRouter, Depends, HTTPException, status, Query, Request, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Optional
from backend.dependencies.__init__ import get_db
from backend.models.blood_requests import BloodRequest, RequestStatusEnum
from backend.models.donor import Donor
from backend.models.hospitals import Hospital
from backend.models.user import User
from backend.schemas.blood_request import (
    BloodRequestCreate,
    BloodRequestResponse,
    BloodRequestListResponse,
    RequestFilterParams
)
from backend.dependencies.auth import get_current_user, get_current_hospital, require_admin
from backend.utils.blood_compatibility import get_compatible_donor_groups
from sqlalchemy import or_
from backend.core.pagination import PaginationParams, PagedResponse
from backend.core.rate_limiter import limiter
from backend.core.cache import get_cached, set_cached, invalidate_cache
from backend.services.notification_services import log_request_created, log_donation_event


router = APIRouter(prefix="/blood-requests", tags=["Blood Requests"])


def build_request_response(req: BloodRequest) -> dict:
    return {
        "id":             req.id,
        "blood_group":    req.blood_group,
        "units_needed":   req.units_needed,
        "patient_name":   req.patient_name,
        "urgency":        req.urgency,
        "status":         req.status,
        "notes":          req.notes,
        "created_at":     req.created_at,
        "hospital_name":  req.hospital.name,
        "hospital_city":  req.hospital.city,
        "hospital_phone": req.hospital.phone,
        "donor_name":     req.donor.user.full_name if req.donor else None,
        "donor_phone":    req.donor.user.phone     if req.donor else None,
    }


# ── HOSPITAL ──────────────────────────────────────────────────────────────────

@router.post("/", response_model=BloodRequestResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
def create_blood_request(
    request:           Request,
    data:              BloodRequestCreate,
    background_tasks:  BackgroundTasks,              # ← inject this
    current_hospital:  Hospital = Depends(get_current_hospital),
    db:                Session = Depends(get_db),
):
    blood_request = BloodRequest(
        hospital_id  = current_hospital.id,
        blood_group  = data.blood_group,
        units_needed = data.units_needed,
        patient_name = data.patient_name,
        urgency      = data.urgency,
        notes        = data.notes,
    )
    db.add(blood_request)
    db.commit()
    db.refresh(blood_request)

    invalidate_cache("blood_requests:*")

    # Add background task — runs after response is sent
    background_tasks.add_task(
        log_request_created,
        request_id    = blood_request.id,
        hospital_name = current_hospital.name,
        blood_group   = data.blood_group.value,
    )

    return build_request_response(blood_request)


@router.get("/my-requests", response_model=BloodRequestListResponse)
def hospital_my_requests(
    current_hospital: Hospital = Depends(get_current_hospital),
    db:               Session = Depends(get_db),
):
    """Hospital sees all their own requests regardless of status."""
    requests = (
        db.query(BloodRequest)
        .filter(BloodRequest.hospital_id == current_hospital.id)
        .order_by(BloodRequest.created_at.desc())
        .all()
    )
    return {"total": len(requests), "requests": [build_request_response(r) for r in requests]}


@router.post("/{request_id}/cancel", response_model=BloodRequestResponse)
def cancel_blood_request(
    request_id:       int,
    current_hospital: Hospital = Depends(get_current_hospital),
    db:               Session = Depends(get_db),
):
    """
    Hospital cancels their own request.
    Cannot cancel already fulfilled requests.
    """
    blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not blood_request:
        raise HTTPException(status_code=404, detail="Blood request not found.")

    if blood_request.hospital_id != current_hospital.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only cancel your own requests.",
        )

    # State guard — prevent illogical transitions
    if blood_request.status == RequestStatusEnum.FULFILLED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot cancel a request that has already been fulfilled.",
        )
    if blood_request.status == RequestStatusEnum.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Request is already cancelled.",
        )

    blood_request.status = RequestStatusEnum.CANCELLED
    db.commit()
    db.refresh(blood_request)

    invalidate_cache("blood_requests:*")

    return build_request_response(blood_request)


# ── DONOR ─────────────────────────────────────────────────────────────────────

@router.get("/matching", response_model=BloodRequestListResponse)
def get_matching_requests(
    current_user: User = Depends(get_current_user),
    db:           Session = Depends(get_db),
):
    """
    Donor sees open requests compatible with their blood group.
    Uses compatibility map — O- donor sees all requests.
    A+ donor sees only A+ and AB+ requests.
    """
    donor = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if not donor:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only registered donors can view matching requests.",
        )

    # Get all blood groups this donor's blood is compatible with
    donor_blood = donor.blood_group.value
    compatible_recipient_groups = [
        group
        for group, compatible_donors in {
            "A+":  ["A+", "A-", "O+", "O-"],
            "A-":  ["A-", "O-"],
            "B+":  ["B+", "B-", "O+", "O-"],
            "B-":  ["B-", "O-"],
            "AB+": ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
            "AB-": ["AB-", "A-", "B-", "O-"],
            "O+":  ["O+", "O-"],
            "O-":  ["O-"],
        }.items()
        if donor_blood in compatible_donors
    ]

    requests = (
        db.query(BloodRequest)
        .filter(
            BloodRequest.status == RequestStatusEnum.OPEN,
            BloodRequest.blood_group.in_(compatible_recipient_groups),
        )
        .order_by(BloodRequest.created_at.desc())
        .all()
    )
    return {"total": len(requests), "requests": [build_request_response(r) for r in requests]}


@router.post("/{request_id}/accept", response_model=BloodRequestResponse)
def accept_blood_request(
    request_id:   int,
    current_user: User = Depends(get_current_user),
    db:           Session = Depends(get_db),
):
    """
    Donor accepts an open request.
    RBAC checks:
    - Must be a registered donor
    - Request must be OPEN
    - Donor must be blood-compatible
    """
    donor = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if not donor:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only registered donors can accept requests.",
        )

    blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not blood_request:
        raise HTTPException(status_code=404, detail="Blood request not found.")

    # State guard
    if blood_request.status != RequestStatusEnum.OPEN:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"This request is already {blood_request.status.value}.",
        )

    # Compatibility guard
    compatible_donors = get_compatible_donor_groups(blood_request.blood_group.value)
    if donor.blood_group.value not in compatible_donors:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Your blood group {donor.blood_group.value} is not compatible with this request ({blood_request.blood_group.value}).",
        )

    blood_request.donor_id = donor.id
    blood_request.status   = RequestStatusEnum.ACCEPTED
    db.commit()
    db.refresh(blood_request)

    invalidate_cache("blood_requests:*")

    return build_request_response(blood_request)


@router.post("/{request_id}/fulfil", response_model=BloodRequestResponse)
def fulfil_blood_request(
    request_id:       int,
    background_tasks: BackgroundTasks,              # ← inject this
    current_user:     User = Depends(get_current_user),
    db:               Session = Depends(get_db),
):
    donor = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if not donor:
        raise HTTPException(status_code=403, detail="Only donors can fulfil requests.")

    blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not blood_request:
        raise HTTPException(status_code=404, detail="Blood request not found.")

    if blood_request.donor_id != donor.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not the assigned donor for this request.",
        )

    if blood_request.status != RequestStatusEnum.ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only accepted requests can be marked as fulfilled.",
        )

    blood_request.status = RequestStatusEnum.FULFILLED
    db.commit()
    db.refresh(blood_request)

    invalidate_cache("blood_requests:*")

    # Add background task — runs after response is sent
    background_tasks.add_task(
        log_donation_event,
        request_id = blood_request.id,
        donor_id   = donor.id,
        db         = db,
    )

    return build_request_response(blood_request)


# ── ADMIN ─────────────────────────────────────────────────────────────────────

@router.get("/admin/all", response_model=BloodRequestListResponse)
def admin_list_all_requests(
    status_filter: Optional[str] = Query(None),
    admin:         User = Depends(require_admin),
    db:            Session = Depends(get_db),
):
    """Admin sees all requests across all hospitals and statuses."""
    query = db.query(BloodRequest)
    if status_filter:
        query = query.filter(BloodRequest.status == status_filter)

    requests = query.order_by(BloodRequest.created_at.desc()).all()
    return {"total": len(requests), "requests": [build_request_response(r) for r in requests]}


@router.patch("/admin/{request_id}/cancel", response_model=BloodRequestResponse)
def admin_cancel_request(
    request_id: int,
    admin:      User = Depends(require_admin),
    db:         Session = Depends(get_db),
):
    """Admin can cancel any request except fulfilled ones."""
    blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
    if not blood_request:
        raise HTTPException(status_code=404, detail="Blood request not found.")

    if blood_request.status == RequestStatusEnum.FULFILLED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot cancel a fulfilled request.",
        )
    if blood_request.status == RequestStatusEnum.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Request is already cancelled.",
        )

    blood_request.status = RequestStatusEnum.CANCELLED
    db.commit()
    db.refresh(blood_request)
    return build_request_response(blood_request)


@router.get("/", response_model=PagedResponse[BloodRequestResponse])
# @limiter.limit("30/minute")
def list_blood_requests(
    request:    Request,
    pagination: PaginationParams = Depends(),
    filters:    RequestFilterParams = Depends(),
    db:         Session = Depends(get_db),
):
    cache_key = (
        f"blood_requests:"
        f"page={pagination.page}:"
        f"size={pagination.page_size}:"
        f"bg={filters.blood_group}:"
        f"city={filters.city}:"
        f"urgency={filters.urgency}:"
        f"status={filters.status}:"
        f"units_min={filters.units_needed_min}"
    )

    cached = get_cached(cache_key)
    if cached:
        return cached

    query = db.query(BloodRequest)

    if filters.blood_group:
        query = query.filter(BloodRequest.blood_group == filters.blood_group)

    if filters.city:
        query = query.join(Hospital, BloodRequest.hospital_id == Hospital.id)\
                     .filter(Hospital.city.ilike(f"%{filters.city}%"))

    if filters.urgency:
        query = query.filter(BloodRequest.urgency == filters.urgency)

    if filters.status:
        query = query.filter(BloodRequest.status == filters.status)

    if filters.units_needed_min is not None:
        query = query.filter(BloodRequest.units_needed >= filters.units_needed_min)

    total = query.count()
    blood_requests = query.offset(pagination.offset).limit(pagination.page_size).all()

    result = PagedResponse.create(
        items=[build_request_response(r) for r in blood_requests],
        total=total,
        params=pagination
    )

    # Shorter TTL — blood requests are more time-sensitive
    set_cached(cache_key, result.model_dump(), ttl_seconds=30)

    return result