# app/dependencies/__init__.py

from typing import Generator
from sqlalchemy.orm import Session
from backend.database import SessionLocal


def get_db() -> Generator[Session, None, None]:
    """
    Dependency that provides a database session per request.

    yield (not return) makes this a context manager.
    The finally block ALWAYS runs — even if your route raises an exception.
    This guarantees no connection leaks, ever.

    Usage in routes:
        def my_route(db: Session = Depends(get_db)):
            db.query(...)
    """
    db = SessionLocal()
    try:
        yield db          # ← route function runs here, with db available
    finally:
        db.close()        # ← always runs, success or failure