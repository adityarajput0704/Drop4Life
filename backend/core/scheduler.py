import logging
from datetime import date
from apscheduler.schedulers.background import BackgroundScheduler
from backend.dependencies.__init__ import get_db
from backend.models.donor import Donor, AvailabilityEnum

logger = logging.getLogger(__name__)

scheduler = BackgroundScheduler()

def reset_expired_cooldowns():
    """
    Runs daily. Finds donors whose cooldown_until date has passed
    and resets their availability to AVAILABLE automatically.
    """
    db = next(get_db())
    try:
        today = date.today()

        expired_donors = (
            db.query(Donor)
            .filter(
                Donor.cooldown_until != None,
                Donor.cooldown_until < today,
                Donor.availability == AvailabilityEnum.UNAVAILABLE,
            )
            .all()
        )

        count = len(expired_donors)
        for donor in expired_donors:
            donor.availability = AvailabilityEnum.AVAILABLE
            logger.info(
                f"[COOLDOWN RESET] Donor ID={donor.id} | "
                f"Cooldown expired on {donor.cooldown_until} | "
                f"Now AVAILABLE"
            )

        db.commit()
        logger.info(f"[SCHEDULER] Cooldown reset complete — {count} donors re-activated")

    except Exception as e:
        logger.error(f"[SCHEDULER ERROR] {e}")
        db.rollback()
    finally:
        db.close()


def start_scheduler():
    scheduler.add_job(
        reset_expired_cooldowns,
        trigger="cron",
        hour=0,           # runs at midnight every day
        minute=0,
        id="reset_cooldowns",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("[SCHEDULER] Started — cooldown reset job registered")