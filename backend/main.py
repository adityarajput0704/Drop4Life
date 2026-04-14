from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.database import Base, engine
from typing import Optional 
from backend.routers import donors, blood_requests, hospitals, users
from backend.firebase import initialize_firebase
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from backend.core.rate_limiter import limiter
from fastapi import WebSocket, WebSocketDisconnect
from backend.core.websocket_manager import manager
import logging
from backend.core.scheduler import start_scheduler
from backend.config import get_settings  

settings = get_settings() 
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

initialize_firebase()

app = FastAPI(
    title="Drop4Life",
    description="API for connecting blood donors with those in need",
    version="1.0.0",
    # redirect_slashes=False,
)

app.add_middleware(
    CORSMiddleware,
    # In dev: reads from .env → "http://localhost:3000,http://localhost:5173"
    # In prod: reads from Render env vars → "https://yourapp.com"
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,    # ← Now safe because origins are explicit
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

# Attach limiter to app state
app.state.limiter = limiter

# Add middleware
app.add_middleware(SlowAPIMiddleware)

# Add error handler — returns 429 when limit is exceeded
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


start_scheduler()

app.include_router(donors.router)
app.include_router(blood_requests.router)
app.include_router(hospitals.router) 
app.include_router(users.router) 

@app.get("/")
def read_root():
    return {
        "status": "running",
        "message": "Welcome to Drop4Life!",
        "version": "1.0.0",
    }


@app.websocket("/ws/{room}")
async def websocket_endpoint(websocket: WebSocket, room: str):
    """
    WebSocket endpoint. Clients connect to a room.
    
    Rooms:
      /ws/admin           → admin dashboard
      /ws/hospital_3      → hospital with id=3
    """
    await manager.connect(websocket, room)
    try:
        while True:
            # Keep connection alive — wait for client messages
            # We don't process client messages yet, just keep alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)

