"""Tests for danger-zone DB lookup in valhalla_client.

Uses a fake AsyncSession so no PostGIS is required. Verifies:
- DB rows are converted to lon/lat rings
- DB failure falls back to bundled JSON defaults
- TTL cache avoids repeated queries
- Empty DB returns defaults rather than silently disabling avoidance
"""

import time
from unittest.mock import AsyncMock, MagicMock

import pytest
from shapely.geometry import Polygon

from app.services import valhalla_client
from app.services.valhalla_client import (
    _DEFAULT_DANGER_ZONES,
    _get_danger_zones,
    _invalidate_zone_cache,
)


class _FakeRow:
    def __init__(self, poly: Polygon):
        self._poly = poly

    @property
    def geometry(self):
        return self._poly


def _fake_session(rows=None, raise_exc: Exception | None = None):
    session = MagicMock()
    scalars_result = MagicMock()
    if raise_exc is not None:
        session.scalars = AsyncMock(side_effect=raise_exc)
    else:
        scalars_result.all.return_value = rows or []
        session.scalars = AsyncMock(return_value=scalars_result)
    return session


@pytest.fixture(autouse=True)
def clear_cache(monkeypatch):
    _invalidate_zone_cache()
    # Patch to_shape so _FakeRow.geometry (already a Polygon) passes through.
    monkeypatch.setattr(valhalla_client, "to_shape", lambda g: g)
    yield
    _invalidate_zone_cache()


@pytest.mark.asyncio
async def test_db_rows_converted_to_lonlat_rings():
    poly = Polygon([(23.30, 42.70), (23.31, 42.70), (23.31, 42.71), (23.30, 42.70)])
    session = _fake_session([_FakeRow(poly)])

    zones = await _get_danger_zones(session)

    assert len(zones) == 1
    # Exterior includes closing point — shapely emits 4 coords here
    assert zones[0][0] == [23.30, 42.70]


@pytest.mark.asyncio
async def test_db_failure_falls_back_to_defaults():
    session = _fake_session(raise_exc=RuntimeError("db down"))

    zones = await _get_danger_zones(session)

    assert zones == _DEFAULT_DANGER_ZONES


@pytest.mark.asyncio
async def test_empty_table_uses_defaults():
    session = _fake_session([])

    zones = await _get_danger_zones(session)

    assert zones == _DEFAULT_DANGER_ZONES


@pytest.mark.asyncio
async def test_cache_ttl_prevents_repeat_query():
    poly = Polygon([(23.30, 42.70), (23.31, 42.70), (23.31, 42.71), (23.30, 42.70)])
    session = _fake_session([_FakeRow(poly)])

    await _get_danger_zones(session)
    await _get_danger_zones(session)
    await _get_danger_zones(session)

    assert session.scalars.call_count == 1


@pytest.mark.asyncio
async def test_cache_invalidate_forces_refetch():
    poly = Polygon([(23.30, 42.70), (23.31, 42.70), (23.31, 42.71), (23.30, 42.70)])
    session = _fake_session([_FakeRow(poly)])

    await _get_danger_zones(session)
    _invalidate_zone_cache()
    await _get_danger_zones(session)

    assert session.scalars.call_count == 2


@pytest.mark.asyncio
async def test_cache_respects_ttl_expiry(monkeypatch):
    poly = Polygon([(23.30, 42.70), (23.31, 42.70), (23.31, 42.71), (23.30, 42.70)])
    session = _fake_session([_FakeRow(poly)])

    # First call stamps cache
    await _get_danger_zones(session)

    # Fast-forward time past TTL
    from app.config import settings

    real_monotonic = time.monotonic
    monkeypatch.setattr(
        valhalla_client.time,
        "monotonic",
        lambda: real_monotonic() + settings.avoid_polygons_cache_ttl + 1,
    )

    await _get_danger_zones(session)
    assert session.scalars.call_count == 2
