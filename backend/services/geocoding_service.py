import httpx
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"

def geocode_address(address: str, city: str) -> Optional[Tuple[float, float]]:
    """
    Geocodes using Nominatim with structured parameters.
    Structured queries are significantly more accurate than free-text.
    """
    headers = {"User-Agent": "Drop4Life/1.0 (blood donation system)"}

    # Strategy 1 — structured query (most accurate)
    try:
        response = httpx.get(
            NOMINATIM_URL,
            params={
                "street":       address,
                "city":         city,
                "country":      "India",
                "format":       "json",
                "limit":        1,
                "addressdetails": 1,
            },
            headers=headers,
            timeout=10.0,
        )
        results = response.json()
        if results:
            lat = float(results[0]["lat"])
            lon = float(results[0]["lon"])
            logger.info(f"[GEOCODE S1] '{address}, {city}' → ({lat}, {lon})")
            return lat, lon
    except Exception as e:
        logger.error(f"[GEOCODE S1 ERROR] {e}")

    # Strategy 2 — free-text with full address
    try:
        response = httpx.get(
            NOMINATIM_URL,
            params={
                "q":      f"{address}, {city}, India",
                "format": "json",
                "limit":  1,
            },
            headers=headers,
            timeout=10.0,
        )
        results = response.json()
        if results:
            lat = float(results[0]["lat"])
            lon = float(results[0]["lon"])
            logger.info(f"[GEOCODE S2] '{address}, {city}' → ({lat}, {lon})")
            return lat, lon
    except Exception as e:
        logger.error(f"[GEOCODE S2 ERROR] {e}")

    # Strategy 3 — city only as last resort
    try:
        response = httpx.get(
            NOMINATIM_URL,
            params={"q": f"{city}, India", "format": "json", "limit": 1},
            headers=headers,
            timeout=10.0,
        )
        results = response.json()
        if results:
            lat = float(results[0]["lat"])
            lon = float(results[0]["lon"])
            logger.warning(f"[GEOCODE S3 fallback] city only → ({lat}, {lon})")
            return lat, lon
    except Exception as e:
        logger.error(f"[GEOCODE S3 ERROR] {e}")

    return None