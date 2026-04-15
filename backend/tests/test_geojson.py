"""Unit tests for GeoJSON bike-lane loading."""

import json
from pathlib import Path

import pytest

ASSETS_DIR = Path(__file__).parent.parent.parent / "assets"


def load_geojson(filename: str) -> dict:
    path = ASSETS_DIR / filename
    with path.open(encoding="utf-8") as f:
        return json.load(f)


@pytest.mark.skipif(
    not (ASSETS_DIR / "velo_sofia_merged.geojson").exists(),
    reason="assets/velo_sofia_merged.geojson not present",
)
def test_bike_lanes_is_valid_geojson():
    data = load_geojson("velo_sofia_merged.geojson")
    assert data["type"] == "FeatureCollection"
    assert isinstance(data["features"], list)
    assert len(data["features"]) > 0


@pytest.mark.skipif(
    not (ASSETS_DIR / "velo_sofia_merged.geojson").exists(),
    reason="assets/velo_sofia_merged.geojson not present",
)
def test_bike_lanes_features_have_required_properties():
    data = load_geojson("velo_sofia_merged.geojson")
    for feature in data["features"]:
        assert feature["type"] == "Feature"
        assert "geometry" in feature
        assert "properties" in feature
        assert feature["geometry"]["type"] == "LineString"
        props = feature["properties"]
        assert "type" in props, "Feature missing 'type' property"


@pytest.mark.skipif(
    not (ASSETS_DIR / "velo_sofia_merged.geojson").exists(),
    reason="assets/velo_sofia_merged.geojson not present",
)
def test_bike_lanes_coordinates_are_in_sofia():
    """All coordinates should be within the Sofia metropolitan bounding box."""
    data = load_geojson("velo_sofia_merged.geojson")
    sofia_bbox = {"min_lon": 23.2, "max_lon": 23.5, "min_lat": 42.6, "max_lat": 42.8}
    out_of_bounds = 0
    for feature in data["features"]:
        for lon, lat in feature["geometry"]["coordinates"]:
            if not (
                sofia_bbox["min_lon"] <= lon <= sofia_bbox["max_lon"]
                and sofia_bbox["min_lat"] <= lat <= sofia_bbox["max_lat"]
            ):
                out_of_bounds += 1
    assert out_of_bounds == 0, f"{out_of_bounds} coordinates outside Sofia bounding box"


def test_avoid_polygons_json_is_valid():
    path = Path(__file__).parent.parent / "app" / "data" / "avoid_polygons.json"
    assert path.exists(), "avoid_polygons.json missing"
    with path.open() as f:
        data = json.load(f)
    assert "dangerous_zones" in data
    assert len(data["dangerous_zones"]) == 3
    for zone in data["dangerous_zones"]:
        assert "name" in zone
        assert "polygon" in zone
        polygon = zone["polygon"]
        assert len(polygon) >= 4, "Polygon must have at least 4 points"
        # First and last points must be the same (closed ring)
        assert polygon[0] == polygon[-1], f"Polygon '{zone['name']}' is not closed"
