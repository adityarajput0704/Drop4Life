import logging
from datetime import datetime
from sqlalchemy.orm import Session
from backend.models.blood_requests import BloodRequest
from backend.models.donor import Donor

# Get a logger for this module
logger = logging.getLogger(__name__)


def log_donation_event(
    request_id: int,
    donor_id: int,
    db: Session,
):
    """
    Background task — runs AFTER the response is sent.
    Logs a fulfilled donation event.

    In Phase 6.5 this becomes a real-time notification via WebSockets.
    In Phase 8 this will trigger an SMS/email via external API.
    For now we log it — the structure is already production-ready.
    """
    try:
        blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
        donor = db.query(Donor).filter(Donor.id == donor_id).first()

        if blood_request and donor:
            logger.info(
                f"[DONATION FULFILLED] "
                f"Request ID: {request_id} | "
                f"Donor ID: {donor_id} | "
                f"Blood Group: {blood_request.blood_group.value} | "
                f"Hospital: {blood_request.hospital.name} | "
                f"Timestamp: {datetime.utcnow().isoformat()}"
            )
    except Exception as e:
        # Background tasks must never crash silently
        # Always log the error so you can debug it
        logger.error(f"[DONATION EVENT ERROR] request_id={request_id} | error={str(e)}")


def log_request_created(
    request_id: int,
    hospital_name: str,
    blood_group: str,
):
    """
    Background task — logs when a new blood request is created.
    No DB call needed here — data passed directly.
    """
    try:
        logger.info(
            f"[REQUEST CREATED] "
            f"Request ID: {request_id} | "
            f"Hospital: {hospital_name} | "
            f"Blood Group: {blood_group} | "
            f"Timestamp: {datetime.utcnow().isoformat()}"
        )
    except Exception as e:
        logger.error(f"[REQUEST CREATED ERROR] request_id={request_id} | error={str(e)}")