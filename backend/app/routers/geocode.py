"""Geocoding endpoint — thin proxy over Photon, restricted to Sofia."""

import json
import logging

import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(tags=["geocode"])

_PHOTON_URL = "https://photon.komoot.io/api"

# Sofia bounding box (west, south, east, north) — matches sofia.mbtiles bounds.
_SOFIA_BBOX = "23.15,42.6,23.55,42.8"
_SOFIA_CENTER_LAT = 42.6977
_SOFIA_CENTER_LON = 23.3219


class GeocodeResult(BaseModel):
    label: str
    lat: float
    lon: float


def _format_label(props: dict) -> str:
    parts = [
        props.get("name"),
        props.get("street"),
        props.get("housenumber"),
        props.get("district"),
        props.get("city") or props.get("town") or props.get("village"),
    ]
    return ", ".join(p for p in parts if p)


@router.get("/geocode", response_model=list[GeocodeResult])
async def geocode(
    q: str = Query(..., min_length=2, description="Search query"),
    limit: int = Query(10, ge=1, le=20),
) -> list[GeocodeResult]:
    params = {
        "q": q,
        "lang": "default",
        "limit": limit,
        "bbox": _SOFIA_BBOX,
        "lat": _SOFIA_CENTER_LAT,
        "lon": _SOFIA_CENTER_LON,
    }

    headers = {
        "User-Agent": "sofia-bike-routing/1.0 (+https://github.com/TUES-2026-PBL-11-klas)",
        "Accept": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0, headers=headers) as client:
            response = await client.get(_PHOTON_URL, params=params)
    except httpx.TimeoutException:
        logger.warning("Photon geocoder timeout for query %r", q)
        raise HTTPException(status_code=504, detail="Geocoder timeout")
    except httpx.ConnectError as exc:
        logger.warning("Photon geocoder connection error: %s", exc)
        raise HTTPException(status_code=503, detail="Cannot reach geocoder")

    if response.status_code != 200:
        logger.warning(
            "Photon returned %s for %r: %s",
            response.status_code,
            q,
            response.text[:200],
        )
        raise HTTPException(
            status_code=502,
            detail=f"Geocoder returned {response.status_code}",
        )

    try:
        data = response.json()
    except (json.JSONDecodeError, ValueError) as exc:
        logger.warning("Photon returned invalid JSON for %r: %s", q, exc)
        raise HTTPException(status_code=502, detail="Geocoder returned invalid JSON")
    results: list[GeocodeResult] = []
    for feature in data.get("features", []):
        coords = feature.get("geometry", {}).get("coordinates") or []
        if len(coords) < 2:
            continue
        lon, lat = coords[0], coords[1]
        label = _format_label(feature.get("properties", {})) or q
        results.append(GeocodeResult(label=label, lat=lat, lon=lon))

    return results
