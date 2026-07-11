"""In-process pub/sub bus feeding the WebSocket status stream.

Everything runs on one asyncio event loop (orchestrator runs are tasks on the
server loop), so publish is a plain sync call and subscribers are queues
drained by their WebSocket handlers.
"""

import asyncio


class EventBus:
    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue] = set()

    def subscribe(self) -> asyncio.Queue:
        queue: asyncio.Queue = asyncio.Queue(maxsize=200)
        self._subscribers.add(queue)
        return queue

    def unsubscribe(self, queue: asyncio.Queue) -> None:
        self._subscribers.discard(queue)

    def publish(self, event: dict) -> None:
        for queue in list(self._subscribers):
            try:
                queue.put_nowait(event)
            except asyncio.QueueFull:
                # Slow client: drop this event for them rather than stall runs.
                pass


bus = EventBus()
