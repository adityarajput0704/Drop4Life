# app/config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import Literal, Optional


class Settings(BaseSettings):
    """
    Single source of truth for all configuration.
    
    Rules:
    - All secrets come from environment variables (never hardcoded)
    - extra="ignore" → Render injects its own vars (PORT, RENDER, etc.)
      We don't want our app to crash because of vars we don't own
    - Required fields (no default) will crash at startup if missing
      This is intentional — fail fast, fail loud
    """

    # ── Database ────────────────────────────────────────────────
    DATABASE_URL: str  # Required — no default. Must be set in env.

    # ── Redis ────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379"

    # ── Firebase ─────────────────────────────────────────────────
    FIREBASE_PROJECT_ID: str  # Required
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "backend/firebase-service-account.json"
    FIREBASE_SERVICE_ACCOUNT_BASE64: Optional[str] = None

    # ── App ──────────────────────────────────────────────────────
    APP_NAME: str = "Drop4Life"
    APP_VERSION: str = "1.0.0"
    
    # "development" | "production" | "testing"
    ENVIRONMENT: Literal["development", "production", "testing"] = "production"
    
    DEBUG: bool = False

    # ── Security ─────────────────────────────────────────────────
    # Used for any internal signing. Even if Firebase handles auth,
    # this is a required hygiene field for production systems.
    SECRET_KEY: str  # Required — generate with: openssl rand -hex 32

    # ── CORS ─────────────────────────────────────────────────────
    # Comma-separated list of allowed origins
    # Dev:  "http://localhost:3000,http://localhost:5173"
    # Prod: "https://yourfrontend.com"
    ALLOWED_ORIGINS: str = "http://localhost:5173,http://localhost:3000"

    # ── Server ───────────────────────────────────────────────────
    # Render sets $PORT dynamically. We read it here.
    PORT: int = 8000

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",   # ← Changed from "forbid". Render injects extra vars.
        case_sensitive=False,
    )

    @property
    def allowed_origins_list(self) -> list[str]:
        """
        Parse comma-separated ALLOWED_ORIGINS into a list.
        ALLOWED_ORIGINS="https://a.com,https://b.com"
        → ["https://a.com", "https://b.com"]
        """
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"


@lru_cache()
def get_settings() -> Settings:
    """
    Cached settings instance.
    lru_cache ensures Settings() is only instantiated once —
    not on every request. This matters for performance.
    """
    return Settings()