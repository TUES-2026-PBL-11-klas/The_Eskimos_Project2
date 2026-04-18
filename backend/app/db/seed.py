"""Seed PostGIS tables from the JSON/GeoJSON files shipped in the repo.

Runs at backend startup. Idempotent: if a table already has rows it's
skipped. To force a re-seed, TRUNCATE the table manually.

The source files are:
- assets/velo_sofia_merged.geojson  -> bike_lane_features
- backend/app/data/avoid_polygons.json -> avoid_polygons
"""

import json
import logging
from pathlib import Path

from shapely.geometry import MultiLineString, Polygon, shape
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import AvoidPolygon, BikeLaneFeature

logger = logging.getLogger(__name__)

_ASSETS_DIR = Path("/app/assets")
_BIKE_LANES_FILE = _ASSETS_DIR / "velo_sofia_merged.geojson"
_AVOID_POLYGONS_FILE = (
    Path(__file__).parent.parent / "data" / "avoid_polygons.json"
)


async def seed_if_empty(session: AsyncSession) -> None:
    await _seed_bike_lanes(session)
    await _seed_avoid_polygons(session)
    await session.commit()


async def _seed_bike_lanes(session: AsyncSession) -> None:
    count = await session.scalar(select(func.count(BikeLaneFeature.id)))
    if count:
        logger.info("bike_lane_features already has %s rows; skipping seed", count)
        return
    if not _BIKE_LANES_FILE.exists():
        logger.warning("bike lanes seed file missing: %s", _BIKE_LANES_FILE)
        return

    logger.info("Seeding bike_lane_features from %s", _BIKE_LANES_FILE)
    with _BIKE_LANES_FILE.open(encoding="utf-8") as f:
        data = json.load(f)

    inserted = 0
    for feature in data.get("features", []):
        geom = shape(feature["geometry"])
        # Normalize LineString -> MultiLineString so one column type fits all.
        if geom.geom_type == "LineString":
            geom = MultiLineString([geom])
        elif geom.geom_type != "MultiLineString":
            # Skip unexpected geometry types (Points, Polygons, etc.).
            continue
        session.add(
            BikeLaneFeature(
                geometry=f"SRID=4326;{geom.wkt}",
                properties=feature.get("properties") or {},
            )
        )
        inserted += 1
    logger.info("Inserted %s bike-lane features", inserted)


async def _seed_avoid_polygons(session: AsyncSession) -> None:
    count = await session.scalar(select(func.count(AvoidPolygon.id)))
    if count:
        logger.info("avoid_polygons already has %s rows; skipping seed", count)
        return
    if not _AVOID_POLYGONS_FILE.exists():
        logger.warning("avoid polygons seed file missing: %s", _AVOID_POLYGONS_FILE)
        return

    logger.info("Seeding avoid_polygons from %s", _AVOID_POLYGONS_FILE)
    with _AVOID_POLYGONS_FILE.open(encoding="utf-8") as f:
        data = json.load(f)

    inserted = 0
    for zone in data.get("dangerous_zones", []):
        # File stores polygons as [[lon, lat], ...] — matches Valhalla's order.
        poly = Polygon(zone["polygon"])
        session.add(
            AvoidPolygon(
                name=zone["name"],
                geometry=f"SRID=4326;{poly.wkt}",
                enabled=True,
            )
        )
        inserted += 1
    logger.info("Inserted %s avoid polygons", inserted)
