from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import bike_lanes, geocode, health, route


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(
        base_url=settings.valhalla_url,
        timeout=30.0,
    )
    yield
    await app.state.http_client.aclose()


app = FastAPI(
    title="Sofia Bike Routing API",
    description="Bicycle routing API backed by Valhalla, using Sofia bike lane data.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(route.router, prefix="/api/v1")
app.include_router(bike_lanes.router, prefix="/api/v1")
app.include_router(geocode.router, prefix="/api/v1")
