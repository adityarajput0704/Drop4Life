import httpx
import logging
from google.oauth2 import service_account
from google.auth.transport.requests import Request as GoogleRequest
from backend.config import get_settings

logger = logging.getLogger(__name__)


FCM_SERVICE_ACCOUNT_FILE = "backend/firebase-service-account.json"
FCM_SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]


def _get_access_token() -> str:
    """
    Get a short-lived OAuth2 access token using the service account.
    FCM HTTP v1 API requires this — NOT the legacy server key.
    """
    credentials = service_account.Credentials.from_service_account_file(
        FCM_SERVICE_ACCOUNT_FILE,
        scopes=FCM_SCOPES,
    )
    credentials.refresh(GoogleRequest())
    return credentials.token


def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: dict = None,
    project_id: str = None,
) -> bool:
    """
    Send a push notification to a single device via FCM HTTP v1 API.
    Returns True on success, False on failure.
    Never raises — failures are logged, not propagated.
    """
    settings = get_settings()
    project_id = project_id or settings.FIREBASE_PROJECT_ID
    try:
        access_token = _get_access_token()

        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

        payload = {
            "message": {
                "token": fcm_token,
                "notification": {
                    "title": title,
                    "body": body,
                },
                "data": {k: str(v) for k, v in (data or {}).items()},
                "android": {
                    "priority": "high",
                    "notification": {
                        "sound": "default",
                        "channel_id": "blood_requests",
                    }
                },
                "apns": {
                    "payload": {
                        "aps": {
                            "sound": "default",
                            "badge": 1,
                        }
                    }
                }
            }
        }

        response = httpx.post(
            url,
            json=payload,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            timeout=10.0,
        )

        if response.status_code == 200:
            logger.info(f"[FCM] Push sent successfully to token: {fcm_token[:20]}...")
            return True
        else:
            logger.error(f"[FCM] Failed: {response.status_code} — {response.text}")
            return False

    except Exception as e:
        logger.error(f"[FCM ERROR] token={fcm_token[:20]}... error={e}")
        return False