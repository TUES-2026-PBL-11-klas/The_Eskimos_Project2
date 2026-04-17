"""HTTP client wrapper for the Valhalla routing engine."""

import json
import logging
from pathlib import Path

import httpx
from fastapi import HTTPException

from app.models.route_request import Coordinate, RouteRequest
from app.models.route_response import ElevationSummary, Maneuver, RouteResponse
from app.profiles.bicycle import PROFILES

logger = logging.getLogger(__name__)

_AVOID_POLYGONS_PATH = Path(__file__).parent.parent / "data" / "avoid_polygons.json"

with _AVOID_POLYGONS_PATH.open() as _f:
    _DANGER_ZONES: list[list[list[float]]] = [
        z["polygon"] for z in json.load(_f)["dangerous_zones"]
    ]


def _build_valhalla_request(req: RouteRequest) -> dict:
    profile = PROFILES[req.profile]

    # Merge hardcoded danger zones + user-supplied polygons
    exclude_polygons: list[list[list[float]]] = []
    if req.avoid_dangerous:
        exclude_polygons.extend(_DANGER_ZONES)
    for user_poly in req.extra_avoid_polygons:
        exclude_polygons.append([[c.lon, c.lat] for c in user_poly])

    payload: dict = {
        "locations": [
            {"lat": req.start.lat, "lon": req.start.lon},
            {"lat": req.end.lat, "lon": req.end.lon},
        ],
        "costing": profile.costing(),
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

    # Collect maneuvers from all legs
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

    # Encoded polyline from shape
    polyline = trip.get("legs", [{}])[0].get("shape", "") if legs else ""

    # Elevation summary (if requested and available)
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


async def get_route(client: httpx.AsyncClient, req: RouteRequest) -> RouteResponse:
    payload = _build_valhalla_request(req)

    logger.debug("Valhalla request: %s", json.dumps(payload, ensure_ascii=False))

    try:
        response = await client.post("/route", json=payload)
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Valhalla timeout")
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Cannot connect to Valhalla")

    if response.status_code == 400:
        valhalla_error = response.json().get("error", response.text)
        raise HTTPException(status_code=400, detail=f"Routing error: {valhalla_error}")

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Valhalla returned {response.status_code}",
        )

    return _parse_response(response.json(), req.include_elevation)


async def check_valhalla_status(client: httpx.AsyncClient) -> dict:
    try:
        response = await client.get("/status", timeout=5.0)
        return response.json()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Valhalla unreachable: {exc}")
