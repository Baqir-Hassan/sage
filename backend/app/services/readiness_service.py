from __future__ import annotations

from sqlalchemy import text

from app.db.session import engine
from app.services.queue_service import get_queue_service
from app.services.storage_service import get_storage_service


def collect_readiness_status() -> dict[str, object]:
    database = _check_database()
    queue = get_queue_service().check_connection()
    storage = get_storage_service().check_connection()

    is_ready = all(
        component.get("ready") is True
        for component in (database, queue, storage)
    )

    return {
        "status": "ready" if is_ready else "not_ready",
        "components": {
            "database": database,
            "queue": queue,
            "storage": storage,
        },
    }


def _check_database() -> dict[str, object]:
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return {"ready": True}
    except Exception as exc:
        return {"ready": False, "detail": str(exc)}
