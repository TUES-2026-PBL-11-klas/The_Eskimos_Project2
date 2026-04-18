"""Async SQLAlchemy setup for the backend.

Exposes a single async engine + sessionmaker bound to settings.database_url.
Tables are created with Base.metadata.create_all on startup (see main.py).
If the schema grows beyond trivial, swap this for Alembic.
"""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config import settings

engine = create_async_engine(settings.database_url, pool_pre_ping=True)

SessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency — yields a scoped session per request."""
    async with SessionLocal() as session:
        yield session
