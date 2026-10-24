"""Live Ride Room WebSocket endpoint for real-time telemetry fan-out.

Streams rider GPS positions (lat, lng, speed, heading, altitude) and membership status.
Fans out updates to all members connected to the ride room via Redis Pub/Sub.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
import logging
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.services.redis_pubsub import ride_pubsub

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Live Rides"])


@router.websocket("/ws/rides/{ride_id}")
@router.websocket("/api/v1/group-rides/convoy-stream")
@router.websocket("/api/v1/group-rides/convoy-stream/{ride_id}")
@router.websocket("/api/v1/convoy/stream")
async def ride_room_websocket(websocket: WebSocket, ride_id: str = "himalayan-squad") -> None:
    """WebSocket connection for real-time ride room positioning.

    Protocol:
    Client sends:
      - `{"type": "telemetry", "rider_id": "...", "rider_name": "...", "lat": 32.24, "lng": 77.18, "speed": 65.2, "heading": 120.0, "altitude": 4280.0, "timestamp": "..."}`
      - `{"type": "queue_flush", "points": [...]}` (batched queued positions after dead zone reconnect)
      - `{"type": "ping"}`

    Server broadcasts to ride_room channel:
      - `{"type": "member_position", "rider_id": "...", "rider_name": "...", "lat": 32.24, "lng": 77.18, "speed": 65.2, "heading": 120.0, "altitude": 4280.0, "timestamp": "..."}`
      - `{"type": "rider_status", "rider_id": "...", "rider_name": "...", "status": "online"|"reconnecting"|"offline", "last_seen": "..."}`
      - `{"type": "pong"}`
    """
    await websocket.accept()
    channel = f"ride_room:{ride_id}"

    current_rider_id: str | None = None
    current_rider_name: str | None = None

    # Task to forward pub/sub messages to the client websocket
    async def _pubsub_forwarder():
        try:
            async for msg in ride_pubsub.subscribe(channel):
                # Don't echo the rider's own exact position message back to themselves
                if (
                    msg.get("type") == "member_position"
                    and current_rider_id
                    and msg.get("rider_id") == current_rider_id
                ):
                    continue

                await websocket.send_text(json.dumps(msg))
        except (WebSocketDisconnect, asyncio.CancelledError):
            pass
        except Exception as exc:
            logger.debug("Forwarder exit for room %s: %s", ride_id, exc)

    forwarder_task = asyncio.create_task(_pubsub_forwarder())

    try:
        while True:
            raw_text = await websocket.receive_text()
            try:
                data: dict[str, Any] = json.loads(raw_text)
            except Exception:
                continue

            msg_type = data.get("type", "telemetry")

            if msg_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong", "time": datetime.now(timezone.utc).isoformat()}))
                continue

            elif msg_type == "telemetry":
                current_rider_id = data.get("rider_id") or current_rider_id or "anonymous"
                current_rider_name = data.get("rider_name") or current_rider_name or "Rider"

                outbound = {
                    "type": "member_position",
                    "rider_id": current_rider_id,
                    "rider_name": current_rider_name,
                    "lat": float(data.get("lat", 0.0)),
                    "lng": float(data.get("lng", 0.0)),
                    "speed": float(data.get("speed", 0.0)),
                    "heading": float(data.get("heading", 0.0)),
                    "altitude": float(data.get("altitude", 0.0)),
                    "timestamp": data.get("timestamp") or datetime.now(timezone.utc).isoformat(),
                }
                await ride_pubsub.publish(channel, outbound)

            elif msg_type == "queue_flush":
                # Flush batch points queued while disconnected in tunnels/dead-zones
                points = data.get("points", [])
                current_rider_id = data.get("rider_id") or current_rider_id
                current_rider_name = data.get("rider_name") or current_rider_name

                # Announce that rider reconnected and is caught up
                await ride_pubsub.publish(channel, {
                    "type": "rider_status",
                    "rider_id": current_rider_id,
                    "rider_name": current_rider_name,
                    "status": "online",
                    "gap_recovered_points": len(points),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                })

                # If points exist, publish the latest point as current position
                if points:
                    latest = points[-1]
                    outbound = {
                        "type": "member_position",
                        "rider_id": current_rider_id,
                        "rider_name": current_rider_name,
                        "lat": float(latest.get("lat", 0.0)),
                        "lng": float(latest.get("lng", 0.0)),
                        "speed": float(latest.get("speed", 0.0)),
                        "heading": float(latest.get("heading", 0.0)),
                        "altitude": float(latest.get("altitude", 0.0)),
                        "timestamp": latest.get("timestamp") or datetime.now(timezone.utc).isoformat(),
                    }
                    await ride_pubsub.publish(channel, outbound)

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected for ride room %s rider %s", ride_id, current_rider_id)
    except Exception as exc:
        logger.warning("WebSocket exception: %s", exc)
    finally:
        forwarder_task.cancel()
        if current_rider_id:
            # Broadcast "reconnecting" rather than leaving dot frozen as active
            await ride_pubsub.publish(channel, {
                "type": "rider_status",
                "rider_id": current_rider_id,
                "rider_name": current_rider_name,
                "status": "reconnecting",
                "last_seen": datetime.now(timezone.utc).isoformat(),
            })
