from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.dependencies.__init__ import get_db
from backend.models.donor import Donor
from backend.models.user import User
from backend.models.blood_requests import BloodRequest
from backend.schemas.donor import DonorCreate, DonorUpdate, DonorResponse, DonorFilterParams
from backend.dependencies.auth import get_current_user
from sqlalchemy import or_
from backend.core.pagination import PaginationParams, PagedResponse
from backend.core.rate_limiter import limiter
from backend.core.cache import get_cached, set_cached, invalidate_cache

router = APIRouter(prefix="/donors", tags=["Donors"])


def build_donor_response(donor: Donor) -> dict:
    """
    Merges donor + user fields into a single flat dict.
    Computes total_donations and lives_saved from the donations relationship.
    """
    # Count only fulfilled donations
    fulfilled = [d for d in donor.donations if d.status == "fulfilled"]
    total_donations = len(fulfilled)
    # Each donation saves approximately 3 lives (standard medical estimate)
    lives_saved = total_donations * 3

    last_donation = None
    if fulfilled:
        last = max(fulfilled, key=lambda d: d.updated_at or d.created_at)
        last_donation = (last.updated_at or last.created_at).isoformat()

    return {
        "id":               donor.id,
        "blood_group":      donor.blood_group,
        "city":             donor.city,
        "age":              donor.age,
        "availability":     donor.availability,
        "is_active":        donor.is_active,
        "full_name":        donor.user.full_name,
        "email":            donor.user.email,
        "phone":            donor.user.phone,
        "total_donations":  total_donations,  
        "lives_saved":      lives_saved,       
        "last_donation":    last_donation,   


    }


@router.post("/register", response_model=DonorResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
def register_donor(
    request:      Request,
    donor_data: DonorCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # One user = one donor profile
    existing = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You already have a donor profile.",
        )

    donor = Donor(
        user_id      = current_user.id,
        blood_group  = donor_data.blood_group,
        city         = donor_data.city,
        age          = donor_data.age,
        availability = donor_data.availability,
    )

    db.add(donor)
    db.commit()
    db.refresh(donor)

    # New donor registered — clear all donor list caches
    invalidate_cache("donors:*")

    return build_donor_response(donor)


@router.get("/me", response_model=DonorResponse)
def get_my_donor_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    donor = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if not donor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No donor profile found. Please register as a donor first.",
        )
    return build_donor_response(donor)



@router.patch("/me", response_model=DonorResponse)
def update_donor_profile(
    updates: DonorUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    donor = db.query(Donor).filter(Donor.user_id == current_user.id).first()
    if not donor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No donor profile found.",
        )

    for field, value in updates.model_dump(exclude_unset=True).items():
        setattr(donor, field, value)

    db.commit()
    db.refresh(donor)
    
    invalidate_cache("donors:*")

    return build_donor_response(donor)


@router.get("/", response_model=PagedResponse[DonorResponse])
@limiter.limit("30/minute")
def list_donors(
    request:    Request,
    pagination: PaginationParams = Depends(),
    filters:    DonorFilterParams = Depends(),
    db:         Session = Depends(get_db),
):
    """Public — paginated donor list with optional filters."""

    # Build a unique cache key from all query params
    cache_key = (
        f"donors:"
        f"page={pagination.page}:"
        f"size={pagination.page_size}:"
        f"bg={filters.blood_group}:"
        f"city={filters.city}:"
        f"avail={filters.is_available}:"
        f"search={filters.search}"
    )

    # Try cache first
    cached = get_cached(cache_key)
    if cached:
        return cached

    # Cache miss — query DB
    query = db.query(Donor).filter(Donor.is_active == True)

    if filters.blood_group:
        query = query.filter(Donor.blood_group == filters.blood_group)

    if filters.city:
        query = query.filter(Donor.city.ilike(f"%{filters.city}%"))

    if filters.is_available is not None:
        query = query.filter(Donor.availability == filters.is_available)

    if filters.search:
        search_term = f"%{filters.search}%"
        query = query.join(User, Donor.user_id == User.id).filter(
            or_(
                User.full_name.ilike(search_term),
                User.phone.ilike(search_term),
            )
        )

    total = query.count()
    donors = query.offset(pagination.offset).limit(pagination.page_size).all()

    result = PagedResponse.create(
        items=[build_donor_response(d) for d in donors],
        total=total,
        params=pagination
    )

    # Store in cache for 60 seconds
    set_cached(cache_key, result.model_dump(), ttl_seconds=60)

    return result