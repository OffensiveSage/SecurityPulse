"""
Security Pulse — Background worker entry point.

Responsibilities (Phase 7 implementation):
- Push notifications for assigned scenarios
- Scheduled campaign publishing
- Analytics export generation

This is a skeleton. The worker task queue (ARQ vs Celery) is pending
ADR-0005. No tasks are implemented in Phase 1.
"""
from __future__ import annotations

import asyncio
import signal
import sys

import structlog

logger = structlog.get_logger(__name__)


class WorkerShutdown(Exception):
    """Raised when the worker receives a shutdown signal."""


async def main() -> None:
    """Worker main loop. Runs until interrupted."""
    logger.info("security_pulse_worker_starting")

    loop = asyncio.get_running_loop()

    shutdown_event = asyncio.Event()

    def _signal_handler(sig: signal.Signals) -> None:
        logger.info("worker_shutdown_signal_received", signal=sig.name)
        shutdown_event.set()

    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, _signal_handler, sig)

    logger.info(
        "worker_ready",
        note="No tasks registered in Phase 1. Waiting for shutdown signal.",
    )

    await shutdown_event.wait()
    logger.info("security_pulse_worker_stopped")


if __name__ == "__main__":
    asyncio.run(main())
