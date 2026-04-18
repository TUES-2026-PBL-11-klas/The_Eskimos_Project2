import logging
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.config import settings
from app.db import SessionLocal, engine
from app.db.models import Base
from app.db.seed import seed_if_empty
from app.routers import bike_lanes, geocode, health, route

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(
        base_url=settings.valhalla_url,
        timeout=30.0,
    )
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    async with SessionLocal() as session:
        try:
            await seed_if_empty(session)
        except Exception:
            logger.exception("Seed step failed; continuing without seed")
    yield
    await app.state.http_client.aclose()
    await engine.dispose()


app = FastAPI(
    title="Sofia Bike Routing API",
    description="Bicycle routing API backed by Valhalla, using Sofia bike lane data.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Accept"],
)

app.include_router(health.router)
app.include_router(route.router, prefix="/api/v1")
app.include_router(bike_lanes.router, prefix="/api/v1")
app.include_router(geocode.router, prefix="/api/v1")
