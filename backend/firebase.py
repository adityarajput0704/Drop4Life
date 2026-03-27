import firebase_admin
from firebase_admin import credentials
from backend.config import get_settings

settings = get_settings()

def initialize_firebase():
    """
    Initialize Firebase Admin SDK once at application startup.
    Checks if already initialized to avoid duplicate app errors
    during hot reloads in development.
    """
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized")