# backend/firebase.py

import firebase_admin
from firebase_admin import credentials
from backend.config import get_settings
import json
import base64

settings = get_settings()


def initialize_firebase():
    """
    Initialize Firebase Admin SDK once at application startup.

    Strategy:
    - Production / Docker: reads credentials from FIREBASE_SERVICE_ACCOUNT_BASE64
      env var (base64-encoded JSON). No file needed inside the container.
    - Local dev: falls back to FIREBASE_SERVICE_ACCOUNT_PATH (the .json file).

    Why base64?
    - Docker images are inspectable. A secret file baked into an image
      is permanently exposed. Env vars are injected at runtime — never
      stored in the image layer.
    """
    if firebase_admin._apps:
        return  # Already initialized — skip (handles hot reload)

    if settings.FIREBASE_SERVICE_ACCOUNT_BASE64:
        # ── Production path ─────────────────────────────────────
        # Decode base64 string → JSON dict → Firebase credential
        decoded = base64.b64decode(
            settings.FIREBASE_SERVICE_ACCOUNT_BASE64
        ).decode("utf-8")
        service_account_info = json.loads(decoded)
        cred = credentials.Certificate(service_account_info)
        print("✅ Firebase initialized from environment variable")

    else:
        # ── Local dev path ───────────────────────────────────────
        # Falls back to the .json file on your local machine
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        print("✅ Firebase initialized from service account file")

    firebase_admin.initialize_app(cred)