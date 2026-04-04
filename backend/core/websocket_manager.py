# backend/core/websocket_manager.py

import logging
from typing import Dict, List
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages active WebSocket connections.
    
    Connections are grouped by room:
      - "admin"        → all admin tabs
      - "hospital_{id}" → specific hospital
      - "donor_{id}"   → specific donor (future)
    
    When an event fires, we broadcast to the relevant room.
    All connected tabs in that room receive the message instantly.
    """

    def __init__(self):
        # room_id → list of active WebSocket connections
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.rooms:
            self.rooms[room] = []
        self.rooms[room].append(websocket)
        logger.info(f"WebSocket connected: room={room} total={len(self.rooms[room])}")

    def disconnect(self, websocket: WebSocket, room: str):
        if room in self.rooms:
            self.rooms[room] = [ws for ws in self.rooms[room] if ws != websocket]
            if not self.rooms[room]:
                del self.rooms[room]
        logger.info(f"WebSocket disconnected: room={room}")

    async def broadcast_to_room(self, room: str, message: dict):
        """Send a message to all connections in a room."""
        if room not in self.rooms:
            return

        dead = []
        for websocket in self.rooms[room]:
            try:
                await websocket.send_json(message)
            except Exception:
                dead.append(websocket)

        # Clean up dead connections
        for ws in dead:
            self.rooms[room] = [w for w in self.rooms[room] if w != ws]

    async def broadcast_to_all(self, message: dict):
        """Send a message to every connected client."""
        for room in list(self.rooms.keys()):
            await self.broadcast_to_room(room, message)


# Single instance — imported everywhere
manager = ConnectionManager()