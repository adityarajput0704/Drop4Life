# app/models/__init__.py
# Import all models here so Alembic can find them when generating migrations

from backend.models.donor import Donor
from backend.models.hospitals import Hospital
from backend.models.blood_requests import BloodRequest
from backend.models.user import User



## Step 3D — Dependency Injection for DB Session

### WHY dependency injection matters

# Every request needs a database session. Every request must close that session when done — even if an error occurs. You could write this in every route function, but that's 50 functions all doing the same boilerplate.

# FastAPI's `Depends()` solves this. Write the session logic once, inject it everywhere.
# ```
# Request arrives → FastAPI calls get_db() → yields session → 
# your route runs → response sent → finally: session closes
# '''