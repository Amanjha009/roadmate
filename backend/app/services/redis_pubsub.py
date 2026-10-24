"""Redis Pub/Sub manager for real-time ride room fan-out with in-memory fallback.

Enables horizontal scaling across multiple backend instances: any instance can publish
a rider's position update to channel `ride_room:{ride_id}`, and all instances with connected
riders in that room receive and dispatch the frame in real time.
"""

from __future__ import annotations

import asyncio
import json
import logging
from collections import defaultdict
from typing import Any, AsyncGenerator

import redis.asyncio as aioredis

from app.config import settings

logger = logging.getLogger(__name__)


class RideRoomPubSubManager:
    """Manages channel subscription and publishing for Ride Rooms.

    Connects to Redis Pub/Sub if available. Falls back gracefully to an
    in-process event bus if Redis is not reachable (e.g. offline dev / testing).
    """

    def __init__(self, redis_url: str | None = None) -> None:
        self.redis_url = redis_url or settings.redis_url
        self._redis: aioredis.Redis | None = None
        self._redis_available: bool | None = None
        # In-memory fallback: channel_name -> set of asyncio.Queue
        self._local_subscribers: dict[str, set[asyncio.Queue]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def get_redis(self) -> aioredis.Redis | None:
        """Lazily initialize and test Redis connection."""
        if self._redis_available is False:
            return None

        if self._redis is None:
            try:
                client = aioredis.from_url(
                    self.redis_url,
                    decode_responses=True,
                    socket_connect_timeout=1.0,
                )
                await client.ping()
                self._redis = client
                self._redis_available = True
                logger.info("Connected to Redis Pub/Sub at %s", self.redis_url)
            except Exception as exc:
                self._redis_available = False
                logger.warning(
                    "Redis unavailable (%s). Falling back to in-memory ride room pub/sub.",
                    exc,
                )
                self._redis = None

        return self._redis

    async def publish(self, channel: str, data: dict[str, Any]) -> None:
        """Publish a telemetry or status frame to a ride room channel."""
        payload = json.dumps(data)

        # 1. Try Redis Pub/Sub for horizontal scaling
        client = await self.get_redis()
        if client is not None:
            try:
                await client.publish(channel, payload)
                # Redis handles pub/sub, but also broadcast locally if needed
            except Exception as exc:
                logger.warning("Redis publish error (%s), routing locally.", exc)
                self._redis_available = False

        # 2. Local in-memory fan-out
        async with self._lock:
            queues = list(self._local_subscribers.get(channel, set()))

        for q in queues:
            try:
                q.put_nowait(data)
            except asyncio.QueueFull:
                logger.warning("Subscriber queue full for channel %s, dropping frame", channel)

    async def subscribe(self, channel: str) -> AsyncGenerator[dict[str, Any], None]:
        """Subscribe to a ride room channel and yield messages as they arrive."""
        queue: asyncio.Queue = asyncio.Queue(maxsize=100)

        async with self._lock:
            self._local_subscribers[channel].add(queue)

        client = await self.get_redis()
        redis_pubsub = None
        redis_listener_task: asyncio.Task | None = None

        if client is not None:
            try:
                redis_pubsub = client.pubsub()
                await redis_pubsub.subscribe(channel)

                async def _reader():
                    try:
                        async for message in redis_pubsub.listen():
                            if message and message.get("type") == "message":
                                raw = message.get("data")
                                if raw:
                                    parsed = json.loads(raw)
                                    await queue.put(parsed)
                    except (asyncio.CancelledError, Exception):
                        pass

                redis_listener_task = asyncio.create_task(_reader())
            except Exception as exc:
                logger.warning("Failed to subscribe via Redis: %s", exc)

        try:
            while True:
                msg = await queue.get()
                yield msg
        finally:
            if redis_listener_task is not None:
                redis_listener_task.cancel()
            if redis_pubsub is not None:
                try:
                    await redis_pubsub.unsubscribe(channel)
                    await redis_pubsub.close()
                except Exception:
                    pass

            async with self._lock:
                if channel in self._local_subscribers:
                    self._local_subscribers[channel].discard(queue)
                    if not self._local_subscribers[channel]:
                        del self._local_subscribers[channel]

    async def close(self) -> None:
        """Close connections and cleanup."""
        if self._redis is not None:
            try:
                await self._redis.close()
            except Exception:
                pass
            self._redis = None


# Global singleton instance
ride_pubsub = RideRoomPubSubManager()
