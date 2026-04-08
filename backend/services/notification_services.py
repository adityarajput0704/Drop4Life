import logging
import asyncio
from datetime import datetime
from sqlalchemy.orm import Session
from backend.models.blood_requests import BloodRequest
from backend.models.donor import Donor
from backend.core.websocket_manager import manager
from backend.dependencies.__init__ import get_db
from fastapi import Depends

logger = logging.getLogger(__name__)


async def _broadcast(room: str, event: dict):
    """Internal helper — broadcast to a room safely."""
    try:
        await manager.broadcast_to_room(room, event)
    except Exception as e:
        logger.error(f"[WS BROADCAST ERROR] room={room} error={e}")


def notify_request_created(
    request_id: int,
    hospital_name: str,
    blood_group: str,
    urgency: str,
    db: Session = Depends(get_db),
):
    """
    Background task — fires after a new blood request is created.
    Broadcasts to:
      - admin room (always)
    Logs the event.
    """
    try:
        logger.info(
            f"[REQUEST CREATED] "
            f"Request ID: {request_id} | "
            f"Hospital: {hospital_name} | "
            f"Blood Group: {blood_group} | "
            f"Timestamp: {datetime.utcnow().isoformat()}"
        )

        event = {
            "event": "request_created",          # ← Flutter listens for "event" key
            "type": "REQUEST_CREATED",
            "payload": {
                "request_id": request_id,
                "hospital_name": hospital_name,
                "blood_group": blood_group,
                "urgency": urgency,
                "timestamp": datetime.utcnow().isoformat(),
            }
        }

        # Run async broadcast from sync background task
        asyncio.run(_broadcast("admin", event))
        asyncio.run(_broadcast("donors", event))
    except Exception as e:
        logger.error(f"[REQUEST CREATED ERROR] request_id={request_id} | error={e}")


def notify_request_accepted(
    request_id: int,
    hospital_id: int,
    donor_name: str,
    blood_group: str,
):
    """
    Background task — fires after a donor accepts a request.
    Broadcasts to:
      - hospital_{id} room → hospital sees donor assigned instantly
      - admin room         → admin sees status change
    """
    try:
        logger.info(
            f"[REQUEST ACCEPTED] "
            f"Request ID: {request_id} | "
            f"Donor: {donor_name} | "
            f"Timestamp: {datetime.utcnow().isoformat()}"
        )

        event = {
            "type": "REQUEST_ACCEPTED",
            "payload": {
                "request_id": request_id,
                "donor_name": donor_name,
                "blood_group": blood_group,
                "timestamp": datetime.utcnow().isoformat(),
            }
        }

        asyncio.run(_broadcast(f"hospital_{hospital_id}", event))
        asyncio.run(_broadcast("admin", event))
        asyncio.run(_broadcast("donors", event))  

    except Exception as e:
        logger.error(f"[REQUEST ACCEPTED ERROR] request_id={request_id} | error={e}")


def notify_donation_fulfilled(
    request_id: int,
    donor_id: int,
    hospital_id: int,
    db: Session,
):
    """
    Background task — fires after a donation is marked fulfilled.
    Broadcasts to admin and hospital rooms.
    """
    try:
        blood_request = db.query(BloodRequest).filter(BloodRequest.id == request_id).first()
        donor = db.query(Donor).filter(Donor.id == donor_id).first()

        if not blood_request or not donor:
            return

        logger.info(
            f"[DONATION FULFILLED] "
            f"Request ID: {request_id} | "
            f"Donor ID: {donor_id} | "
            f"Blood Group: {blood_request.blood_group.value} | "
            f"Hospital: {blood_request.hospital.name} | "
            f"Timestamp: {datetime.utcnow().isoformat()}"
        )

        event = {
            "type": "REQUEST_FULFILLED",
            "payload": {
                "request_id": request_id,
                "blood_group": blood_request.blood_group.value,
                "hospital_name": blood_request.hospital.name,
                "timestamp": datetime.utcnow().isoformat(),
            }
        }

        asyncio.run(_broadcast("admin", event))
        asyncio.run(_broadcast(f"hospital_{hospital_id}", event))

    except Exception as e:
        logger.error(f"[DONATION FULFILLED ERROR] request_id={request_id} | error={e}")