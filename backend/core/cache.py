import redis
import json
from typing import Optional, Any
from backend.config import get_settings

settings = get_settings()

# Single Redis client instance — reused across all requests
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def get_cached(key: str) -> Optional[Any]:
    """
    Retrieve a value from Redis cache.
    Returns None if key doesn't exist or Redis is unavailable.
    """
    try:
        data = redis_client.get(key)
        if data:
            return json.loads(data)
        return None
    except Exception:
        # If Redis is down, fail silently — fall through to DB
        return None


def set_cached(key: str, value: Any, ttl_seconds: int = 60):
    """
    Store a value in Redis cache with a TTL (time to live).
    After TTL expires, Redis automatically deletes the key.
    """
    try:
        redis_client.setex(
            name=key,
            time=ttl_seconds,
            value=json.dumps(value, default=str)  # default=str handles datetime serialization
        )
    except Exception:
        # If Redis is down, fail silently — the DB result still gets returned
        pass


def invalidate_cache(pattern: str):
    """
    Delete all cache keys matching a pattern.
    Called when data changes so stale cache is cleared.

    Example: invalidate_cache("donors:*") clears all donor list caches.
    """
    try:
        keys = redis_client.keys(pattern)
        if keys:
            redis_client.delete(*keys)
    except Exception:
        pass