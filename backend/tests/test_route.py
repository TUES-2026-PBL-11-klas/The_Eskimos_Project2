"""Unit tests for route request building and response parsing."""

import json
from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest

from app.models.route_request import Coordinate, RouteRequest
from app.services.valhalla_client import _build_valhalla_request, get_route

SOFIA_CENTER = Coordinate(lat=42.6977, lon=23.3219)
LOZENETS = Coordinate(lat=42.6833, lon=23.3147)


def test_build_request_city_bike():
    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS, profile="city_bike")
    payload = _build_valhalla_request(req)

    assert payload["costing"] == "bicycle"
    assert payload["costing_options"]["bicycle"]["use_roads"] == 0.1
    assert payload["costing_options"]["bicycle"]["bicycle_type"] == "Hybrid"
    assert len(payload["locations"]) == 2
    assert payload["locations"][0] == {"lat": 42.6977, "lon": 23.3219}
    assert "exclude_polygons" in payload  # avoid_dangerous=True by default
    assert len(payload["exclude_polygons"]) == 3  # 3 danger zones
    assert payload["elevation_interval"] == 30  # include_elevation=True by default


def test_build_request_mountain_bike():
    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS, profile="mountain_bike")
    payload = _build_valhalla_request(req)
    assert payload["costing_options"]["bicycle"]["bicycle_type"] == "Mountain"
    assert payload["costing_options"]["bicycle"]["use_hills"] == 0.8


def test_build_request_electric_bike_no_hills():
    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS, profile="electric_bike")
    payload = _build_valhalla_request(req)
    assert payload["costing_options"]["bicycle"]["use_hills"] == 0.0


def test_build_request_no_dangerous_zones():
    req = RouteRequest(
        start=SOFIA_CENTER, end=LOZENETS, avoid_dangerous=False
    )
    payload = _build_valhalla_request(req)
    assert "exclude_polygons" not in payload


def test_build_request_no_elevation():
    req = RouteRequest(
        start=SOFIA_CENTER, end=LOZENETS, include_elevation=False
    )
    payload = _build_valhalla_request(req)
    assert "elevation_interval" not in payload


def test_build_request_extra_avoid_polygon():
    extra = [
        Coordinate(lat=42.70, lon=23.33),
        Coordinate(lat=42.71, lon=23.33),
        Coordinate(lat=42.71, lon=23.34),
        Coordinate(lat=42.70, lon=23.34),
    ]
    req = RouteRequest(
        start=SOFIA_CENTER, end=LOZENETS, extra_avoid_polygons=[extra]
    )
    payload = _build_valhalla_request(req)
    # 3 hardcoded + 1 user-supplied
    assert len(payload["exclude_polygons"]) == 4


def test_invalid_profile_raises():
    with pytest.raises(ValueError, match="Unknown profile"):
        RouteRequest(start=SOFIA_CENTER, end=LOZENETS, profile="jetski")


@pytest.mark.asyncio
async def test_get_route_success():
    valhalla_response = {
        "trip": {
            "summary": {"length": 3.5, "time": 900},
            "legs": [
                {
                    "shape": "encoded_polyline_here",
                    "maneuvers": [
                        {
                            "instruction": "Turn right",
                            "street_names": ["бул. Витоша"],
                            "length": 1.2,
                            "time": 300,
                            "type": 10,
                        }
                    ],
                    "elevation": [550.0, 555.0, 560.0],
                }
            ],
        }
    }

    mock_client = AsyncMock(spec=httpx.AsyncClient)
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = valhalla_response
    mock_client.post.return_value = mock_response

    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS)
    result = await get_route(mock_client, req)

    assert result.distance_km == 3.5
    assert result.duration_minutes == 15.0
    assert result.polyline == "encoded_polyline_here"
    assert len(result.maneuvers) == 1
    assert result.maneuvers[0].instruction == "Turn right"
    assert result.elevation is not None
    assert result.elevation.min_elevation == 550.0


@pytest.mark.asyncio
async def test_get_route_valhalla_400():
    from fastapi import HTTPException

    mock_client = AsyncMock(spec=httpx.AsyncClient)
    mock_response = MagicMock()
    mock_response.status_code = 400
    mock_response.json.return_value = {"error": "No route found"}
    mock_client.post.return_value = mock_response

    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS)
    with pytest.raises(HTTPException) as exc_info:
        await get_route(mock_client, req)
    assert exc_info.value.status_code == 400
    assert "No route found" in exc_info.value.detail


@pytest.mark.asyncio
async def test_get_route_valhalla_timeout():
    from fastapi import HTTPException

    mock_client = AsyncMock(spec=httpx.AsyncClient)
    mock_client.post.side_effect = httpx.TimeoutException("timeout")

    req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS)
    with pytest.raises(HTTPException) as exc_info:
        await get_route(mock_client, req)
    assert exc_info.value.status_code == 504
