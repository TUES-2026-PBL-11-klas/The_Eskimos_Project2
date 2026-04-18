"""Unit tests for GeoJSON bike-lane loading.

These tests are deliberately tolerant about feature properties and geometry
shape: the Sofia bike-lane data is periodically rebuilt from OSM + the custom
overlay, and both the property schema (OSM tags vs. hand-authored keys) and
the geometry mix (LineString vs. MultiLineString) vary between rebuilds. The
tests assert structural invariants (valid GeoJSON, coordinates in Sofia) that
must hold regardless of format drift.
"""

import json
from collections.abc import Iterator
from pathlib import Path

import pytest

ASSETS_DIR = Path(__file__).parent.parent.parent / "assets"
BIKE_LANES_FILE = "velo_sofia_merged.geojson"

# Geometry types we accept — everything in the bike-lane file should be a
# line-like feature, but the merge can produce Multi* variants.
_LINE_GEOMETRY_TYPES = {"LineString", "MultiLineString"}


def load_geojson(filename: str) -> dict:
    path = ASSETS_DIR / filename
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def iter_coordinates(geometry: dict) -> Iterator[tuple[float, float]]:
    """Yield (lon, lat) pairs from any GeoJSON geometry.

    Walks arbitrarily-nested coordinate arrays so the same call works for
    Point, LineString, MultiLineString, Polygon, and MultiPolygon. A coordinate
    is recognised as the innermost list whose first element is a number.
    """
    coords = geometry.get("coordinates")
    if coords is None:
        return

    def _walk(node):
        if (
            isinstance(node, (list, tuple))
            and node
            and isinstance(node[0], (int, float))
        ):
            # Leaf: [lon, lat] or [lon, lat, elevation]
            if len(node) >= 2:
                yield float(node[0]), float(node[1])
            return
        if isinstance(node, (list, tuple)):
            for child in node:
                yield from _walk(child)

    yield from _walk(coords)


skip_if_missing = pytest.mark.skipif(
    not (ASSETS_DIR / BIKE_LANES_FILE).exists(),
    reason=f"assets/{BIKE_LANES_FILE} not present",
)


@skip_if_missing
def test_bike_lanes_is_valid_geojson():
    data = load_geojson(BIKE_LANES_FILE)
    assert data["type"] == "FeatureCollection"
    assert isinstance(data["features"], list)
    assert len(data["features"]) > 0


@skip_if_missing
def test_bike_lanes_features_are_structurally_valid():
    """Every feature has the GeoJSON-required shape.

    Deliberately does NOT assert on specific property keys — the property
    schema depends on the upstream data source (hand-authored overlay vs. OSM
    tags) and is allowed to drift.
    """
    data = load_geojson(BIKE_LANES_FILE)
    for i, feature in enumerate(data["features"]):
        assert feature.get("type") == "Feature", f"feature {i} is not type=Feature"
        assert isinstance(
            feature.get("geometry"), dict
        ), f"feature {i} missing geometry"
        assert isinstance(
            feature.get("properties"), dict
        ), f"feature {i} missing properties"
        geom_type = feature["geometry"].get("type")
        assert geom_type in _LINE_GEOMETRY_TYPES, (
            f"feature {i} has unexpected geometry type {geom_type!r}; "
            f"expected one of {_LINE_GEOMETRY_TYPES}"
        )


@skip_if_missing
def test_bike_lanes_coordinates_are_in_sofia():
    """The bulk of coordinates should fall inside the Sofia metropolitan bbox.

    A small fraction is allowed outside (up to OUT_OF_BOUNDS_TOLERANCE) so that
    bike-lane segments reaching just past the city edge don't break the suite.
    The tolerance is tight enough to still catch catastrophic errors like
    swapped lat/lon or wrong-hemisphere data.
    """
    OUT_OF_BOUNDS_TOLERANCE = 0.02  # 2%

    data = load_geojson(BIKE_LANES_FILE)
    sofia_bbox = {"min_lon": 23.2, "max_lon": 23.5, "min_lat": 42.6, "max_lat": 42.8}

    out_of_bounds: list[tuple[float, float]] = []
    total = 0
    for feature in data["features"]:
        for lon, lat in iter_coordinates(feature["geometry"]):
            total += 1
            if not (
                sofia_bbox["min_lon"] <= lon <= sofia_bbox["max_lon"]
                and sofia_bbox["min_lat"] <= lat <= sofia_bbox["max_lat"]
            ):
                out_of_bounds.append((lon, lat))

    assert total > 0, "no coordinates found in bike-lanes geojson"
    ratio = len(out_of_bounds) / total
    assert ratio <= OUT_OF_BOUNDS_TOLERANCE, (
        f"{len(out_of_bounds)} / {total} ({ratio:.2%}) coordinates outside "
        f"Sofia bbox exceeds tolerance {OUT_OF_BOUNDS_TOLERANCE:.0%}; "
        f"first few: {out_of_bounds[:3]}"
    )


def test_avoid_polygons_json_is_valid():
    path = Path(__file__).parent.parent / "app" / "data" / "avoid_polygons.json"
    assert path.exists(), "avoid_polygons.json missing"
    with path.open() as f:
        data = json.load(f)
    assert "dangerous_zones" in data
    assert len(data["dangerous_zones"]) >= 1
    for zone in data["dangerous_zones"]:
        assert "name" in zone
        assert "polygon" in zone
        polygon = zone["polygon"]
        assert len(polygon) >= 4, "Polygon must have at least 4 points"
        # First and last points must be the same (closed ring)
        assert polygon[0] == polygon[-1], f"Polygon '{zone['name']}' is not closed"
