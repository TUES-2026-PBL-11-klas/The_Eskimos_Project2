"""HTTP client wrapper for the Valhalla routing engine."""

import json
import logging
import time
from pathlib import Path

import httpx
from fastapi import HTTPException
from geoalchemy2.shape import to_shape
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.models import AvoidPolygon
from app.models.route_request import RouteRequest
from app.models.route_response import ElevationSummary, Maneuver, RouteResponse
from app.profiles.bicycle import PROFILES

logger = logging.getLogger(__name__)

_AVOID_POLYGONS_PATH = Path(__file__).parent.parent / "data" / "avoid_polygons.json"

# Loaded at import time. Used as (a) the default for _build_valhalla_request so
# sync tests still pass, and (b) a fallback if the DB query fails at runtime.
with _AVOID_POLYGONS_PATH.open() as _f:
    _DEFAULT_DANGER_ZONES: list[list[list[float]]] = [
        z["polygon"] for z in json.load(_f)["dangerous_zones"]
    ]

# TTL cache for DB-fetched polygons.
_zone_cache: dict = {"zones": None, "ts": 0.0}


def _invalidate_zone_cache() -> None:
    _zone_cache["zones"] = None
    _zone_cache["ts"] = 0.0


async def _get_danger_zones(session: AsyncSession) -> list[list[list[float]]]:
    now = time.monotonic()
    cached = _zone_cache["zones"]
    if cached is not None and now - _zone_cache["ts"] < settings.avoid_polygons_cache_ttl:
        return cached

    try:
        rows = (
            await session.scalars(
                select(AvoidPolygon).where(AvoidPolygon.enabled.is_(True))
            )
        ).all()
        zones: list[list[list[float]]] = []
        for row in rows:
            poly = to_shape(row.geometry)
            # Valhalla expects [[lon, lat], ...] rings.
            zones.append([[float(x), float(y)] for x, y in poly.exterior.coords])
    except Exception as exc:
        logger.warning("DB danger-zone fetch failed; using defaults: %s", exc)
        zones = list(_DEFAULT_DANGER_ZONES)

    if not zones:
        # Empty table shouldn't silently disable danger-zone avoidance.
        zones = list(_DEFAULT_DANGER_ZONES)

    _zone_cache["zones"] = zones
    _zone_cache["ts"] = now
    return zones


def _build_valhalla_request(
    req: RouteRequest,
    danger_zones: list[list[list[float]]] | None = None,
) -> dict:
    profile = PROFILES[req.profile]
    zones = danger_zones if danger_zones is not None else _DEFAULT_DANGER_ZONES

    exclude_polygons: list[list[list[float]]] = []
    if req.avoid_dangerous:
        exclude_polygons.extend(zones)
    for user_poly in req.extra_avoid_polygons:
        exclude_polygons.append([[c.lon, c.lat] for c in user_poly])

    payload: dict = {
        "locations": [
            {"lat": req.start.lat, "lon": req.start.lon},
            {"lat": req.end.lat, "lon": req.end.lon},
        ],
        "costing": profile.costing,
        "costing_options": profile.costing_options(),
        "directions_options": {
            "units": "kilometers",
            "language": req.language,
        },
    }

    if exclude_polygons:
        payload["exclude_polygons"] = exclude_polygons

    if req.include_elevation:
        payload["elevation_interval"] = 30

    return payload


def _parse_response(data: dict, include_elevation: bool) -> RouteResponse:
    trip = data.get("trip", {})
    summary = trip.get("summary", {})

    distance_km = summary.get("length", 0.0)
    duration_minutes = summary.get("time", 0.0) / 60.0
    warnings: list[str] = []

    maneuvers: list[Maneuver] = []
    legs = trip.get("legs", [])
    for leg in legs:
        for m in leg.get("maneuvers", []):
            maneuvers.append(
                Maneuver(
                    instruction=m.get("instruction", ""),
                    street_names=m.get("street_names", []),
                    length_km=m.get("length", 0.0),
                    time_seconds=m.get("time", 0.0),
                    type=m.get("type", 0),
                    begin_shape_index=m.get("begin_shape_index", 0),
                    end_shape_index=m.get("end_shape_index", 0),
                )
            )

    polyline = trip.get("legs", [{}])[0].get("shape", "") if legs else ""

    elevation: ElevationSummary | None = None
    if include_elevation:
        elevations: list[float] = []
        for leg in legs:
            elevations.extend(leg.get("elevation", []))
        if elevations:
            elevation = ElevationSummary(
                min_elevation=min(elevations),
                max_elevation=max(elevations),
                mean_elevation=sum(elevations) / len(elevations),
            )

    if data.get("warnings"):
        warnings = [str(w) for w in data["warnings"]]

    return RouteResponse(
        distance_km=distance_km,
        duration_minutes=round(duration_minutes, 1),
        polyline=polyline,
        legs=legs,
        elevation=elevation,
        maneuvers=maneuvers,
        warnings=warnings,
    )


def _safe_json(response: httpx.Response, upstream: str) -> dict:
    try:
        return response.json()
    except (json.JSONDecodeError, ValueError) as exc:
        logger.warning("%s returned invalid JSON: %s", upstream, exc)
        raise HTTPException(
            status_code=502,
            detail=f"{upstream} returned invalid JSON",
        )


async def get_route(
    client: httpx.AsyncClient,
    req: RouteRequest,
    session: AsyncSession | None = None,
) -> RouteResponse:
    danger_zones: list[list[list[float]]] | None = None
    if session is not None:
        danger_zones = await _get_danger_zones(session)
    payload = _build_valhalla_request(req, danger_zones=danger_zones)

    logger.debug("Valhalla request: %s", json.dumps(payload, ensure_ascii=False))

    try:
        response = await client.post("/route", json=payload)
    except httpx.TimeoutException:
        logger.warning("Valhalla /route timeout")
        raise HTTPException(status_code=504, detail="Valhalla timeout")
    except httpx.ConnectError as exc:
        logger.warning("Valhalla /route connection error: %s", exc)
        raise HTTPException(status_code=503, detail="Cannot connect to Valhalla")

    status = response.status_code
    if status == 200:
        return _parse_response(_safe_json(response, "Valhalla"), req.include_elevation)

    if status in (400, 404, 422):
        body = _safe_json(response, "Valhalla")
        err = body.get("error", response.text)
        logger.info("Valhalla rejected request (%s): %s", status, err)
        raise HTTPException(status_code=status, detail=f"Routing error: {err}")

    if status == 429:
        logger.warning("Valhalla rate-limited us")
        raise HTTPException(status_code=429, detail="Routing engine rate limit")

    logger.warning("Valhalla returned unexpected status %s: %s", status, response.text[:500])
    raise HTTPException(
        status_code=502,
        detail=f"Valhalla returned {status}",
    )


async def check_valhalla_status(client: httpx.AsyncClient) -> dict:
    try:
        response = await client.get("/status", timeout=5.0)
    except (httpx.RequestError, httpx.HTTPStatusError) as exc:
        logger.warning("Valhalla /status unreachable: %s", exc)
        raise HTTPException(status_code=503, detail="Valhalla unreachable")
    if response.status_code != 200:
        logger.warning("Valhalla /status returned %s", response.status_code)
        raise HTTPException(
            status_code=503,
            detail=f"Valhalla unhealthy (status {response.status_code})",
        )
    return _safe_json(response, "Valhalla")
