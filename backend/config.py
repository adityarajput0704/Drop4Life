# app/config.py

from pydantic_settings import BaseSettings
from functools import lru_cache
from pydantic_settings import SettingsConfigDict

class Settings(BaseSettings):
    """
    Reads values from .env automatically.
    Type annotations enforce types — DATABASE_URL must be a str.
    If .env is missing a required value, app crashes at startup with a clear error.
    This is intentional — better to crash loudly than run with wrong config.
    """
    DATABASE_URL: str
    FIREBASE_PROJECT_ID: str
    ENVIRONMENT : str # default to production if not set
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "backend/firebase-service-account.json"
    REDIS_URL: str = "redis://localhost:6379"
    # App
    app_name: str = "Drop4Life"
    debug: bool = False

    model_config = SettingsConfigDict(env_file=".env", extra="forbid")


@lru_cache()
def get_settings() -> Settings:
    return Settings()
