"""Bike-lane feature endpoint, backed by PostGIS."""

import hashlib
import json
import logging

from fastapi import APIRouter, Depends, Header, Response
from geoalchemy2.shape import to_shape
from shapely.geometry import mapping
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.db.models import BikeLaneFeature

logger = logging.getLogger(__name__)

router = APIRouter(tags=["bike-lanes"])

# In-memory cache of the serialized FeatureCollection payload and its ETag.
# Invalidated by restarts; fine for a dataset that only changes via admin edits.
_CACHE: dict[str, str] = {}


async def _build_payload(session: AsyncSession) -> tuple[str, str]:
    """Return (etag, json_body). Memoized in _CACHE after first call."""
    if "etag" in _CACHE and "body" in _CACHE:
        return _CACHE["etag"], _CACHE["body"]

    rows = (await session.scalars(select(BikeLaneFeature))).all()
    features = []
    for row in rows:
        geom = to_shape(row.geometry)
        features.append(
            {
                "type": "Feature",
                "geometry": mapping(geom),
                "properties": row.properties or {},
            }
        )
    body = json.dumps(
        {"type": "FeatureCollection", "features": features},
        ensure_ascii=False,
        separators=(",", ":"),
    )
    etag = '"' + hashlib.sha256(body.encode("utf-8")).hexdigest()[:32] + '"'
    _CACHE["etag"] = etag
    _CACHE["body"] = body
    logger.info("Cached bike-lanes payload (%d features, %d bytes)", len(features), len(body))
    return etag, body


@router.get("/bike-lanes")
async def get_bike_lanes(
    response: Response,
    session: AsyncSession = Depends(get_session),
    if_none_match: str | None = Header(default=None),
):
    etag, body = await _build_payload(session)
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = "public, max-age=300"
    if if_none_match == etag:
        return Response(status_code=304, headers=dict(response.headers))
    return Response(
        content=body,
        media_type="application/json",
        headers=dict(response.headers),
    )
