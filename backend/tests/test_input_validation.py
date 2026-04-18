"""Tests for RouteRequest input validation — coord bounds, polygon caps, language."""

import pytest
from pydantic import ValidationError

from app.models.route_request import Coordinate, RouteRequest

SOFIA_CENTER = Coordinate(lat=42.6977, lon=23.3219)
LOZENETS = Coordinate(lat=42.6833, lon=23.3147)


def test_latitude_out_of_sofia_bbox_rejected():
    with pytest.raises(ValidationError):
        Coordinate(lat=48.0, lon=23.3)


def test_longitude_out_of_sofia_bbox_rejected():
    with pytest.raises(ValidationError):
        Coordinate(lat=42.7, lon=10.0)


def test_invalid_language_rejected():
    with pytest.raises(ValidationError):
        RouteRequest(start=SOFIA_CENTER, end=LOZENETS, language="fr-FR")


def test_valid_languages():
    for lang in ("bg-BG", "en-US"):
        req = RouteRequest(start=SOFIA_CENTER, end=LOZENETS, language=lang)
        assert req.language == lang


def test_too_many_polygons_rejected():
    poly = [Coordinate(lat=42.70, lon=23.33)] * 4
    with pytest.raises(ValidationError):
        RouteRequest(
            start=SOFIA_CENTER,
            end=LOZENETS,
            extra_avoid_polygons=[poly] * 21,
        )


def test_polygon_too_many_vertices_rejected():
    huge = [Coordinate(lat=42.70, lon=23.33)] * 101
    with pytest.raises(ValidationError):
        RouteRequest(
            start=SOFIA_CENTER,
            end=LOZENETS,
            extra_avoid_polygons=[huge],
        )


def test_total_vertex_count_cap():
    poly = [Coordinate(lat=42.70, lon=23.33)] * 100
    with pytest.raises(ValidationError):
        RouteRequest(
            start=SOFIA_CENTER,
            end=LOZENETS,
            extra_avoid_polygons=[poly] * 11,  # 1100 > 1000 cap
        )


def test_valid_polygon_passes():
    poly = [
        Coordinate(lat=42.70, lon=23.33),
        Coordinate(lat=42.71, lon=23.33),
        Coordinate(lat=42.71, lon=23.34),
        Coordinate(lat=42.70, lon=23.34),
    ]
    req = RouteRequest(
        start=SOFIA_CENTER, end=LOZENETS, extra_avoid_polygons=[poly]
    )
    assert len(req.extra_avoid_polygons) == 1
    assert len(req.extra_avoid_polygons[0]) == 4
