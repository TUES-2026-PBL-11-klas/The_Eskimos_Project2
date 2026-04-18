"""Tests for the Photon geocoder proxy."""

from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest
from fastapi import HTTPException

from app.routers.geocode import geocode


def _mock_response(status_code: int, json_data=None, raise_on_json: bool = False):
    resp = MagicMock()
    resp.status_code = status_code
    resp.text = "" if json_data is None else str(json_data)
    if raise_on_json:
        resp.json.side_effect = ValueError("not json")
    else:
        resp.json.return_value = json_data or {}
    return resp


def _patch_client(response_or_exc):
    client = AsyncMock(spec=httpx.AsyncClient)
    if isinstance(response_or_exc, Exception):
        client.get.side_effect = response_or_exc
    else:
        client.get.return_value = response_or_exc
    client.__aenter__.return_value = client
    client.__aexit__.return_value = None
    return patch("app.routers.geocode.httpx.AsyncClient", return_value=client)


@pytest.mark.asyncio
async def test_geocode_happy_path():
    photon = {
        "features": [
            {
                "geometry": {"coordinates": [23.32, 42.70]},
                "properties": {"name": "НДК", "city": "София"},
            }
        ]
    }
    with _patch_client(_mock_response(200, photon)):
        results = await geocode(q="ндк")
    assert len(results) == 1
    assert results[0].label == "НДК, София"
    assert results[0].lat == 42.70
    assert results[0].lon == 23.32


@pytest.mark.asyncio
async def test_geocode_skips_features_without_coords():
    photon = {"features": [{"geometry": {"coordinates": []}, "properties": {}}]}
    with _patch_client(_mock_response(200, photon)):
        results = await geocode(q="noop")
    assert results == []


@pytest.mark.asyncio
async def test_geocode_invalid_json_upstream():
    with _patch_client(_mock_response(200, raise_on_json=True)):
        with pytest.raises(HTTPException) as exc:
            await geocode(q="broken")
    assert exc.value.status_code == 502


@pytest.mark.asyncio
async def test_geocode_timeout():
    with _patch_client(httpx.TimeoutException("boom")):
        with pytest.raises(HTTPException) as exc:
            await geocode(q="slow")
    assert exc.value.status_code == 504


@pytest.mark.asyncio
async def test_geocode_upstream_5xx():
    with _patch_client(_mock_response(503, {})):
        with pytest.raises(HTTPException) as exc:
            await geocode(q="oops")
    assert exc.value.status_code == 502


@pytest.mark.asyncio
async def test_geocode_connect_error():
    with _patch_client(httpx.ConnectError("refused")):
        with pytest.raises(HTTPException) as exc:
            await geocode(q="offline")
    assert exc.value.status_code == 503
