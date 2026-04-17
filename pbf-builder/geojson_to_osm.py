#!/usr/bin/env python3
"""Convert velo_sofia_merged.geojson to OSM PBF format.
Each GeoJSON LineString feature becomes an OSM way with nodes.
Node/way IDs start at 10_000_000_000_000 to avoid conflicts with real OSM data
"""

import json
import sys
from pathlib import Path

import osmium
import osmium.osm.mutable as mutable

# IDs far above current max OSM IDs to avoid conflicts after merge
NODE_ID_START = 10_000_000_000_000
WAY_ID_START = 10_000_000_000_000

# GeoJSON Bulgarian type -> OSM tags mapping
TYPE_TAGS: dict[str, dict[str, str]] = {
    "Контрафлоу": {
        "highway": "cycleway",
        "cycleway": "opposite_lane",
    },
    "На пътното платно": {
        "highway": "cycleway",
        "cycleway": "lane",
    },
    "На пътното платно обособена": {
        "highway": "cycleway",
        "cycleway": "track",
    },
    "На тротоара": {
        "highway": "footway",
        "bicycle": "yes",
        "cycleway": "shared",
    },
    "На тротоара обособена": {
        "highway": "cycleway",
        "cycleway": "track",
        "segregated": "yes",
    },
    "На тротоара споделена с пешеходци": {
        "highway": "footway",
        "bicycle": "yes",
        "foot": "yes",
        "cycleway": "shared",
    },
}

FALLBACK_TAGS: dict[str, str] = {"highway": "cycleway"}


def convert(geojson_path: str, output_path: str) -> None:
    src = Path(geojson_path)
    if not src.exists():
        print(f"ERROR: GeoJSON file not found: {geojson_path}", file=sys.stderr)
        sys.exit(1)

    with src.open(encoding="utf-8") as f:
        data = json.load(f)

    features = data.get("features", [])
    writer = osmium.SimpleWriter(output_path)

    node_id = NODE_ID_START
    way_id = WAY_ID_START
    skipped = 0

    # Two-pass: osmium requires all nodes written before any way.
    pending_ways: list[tuple[int, list[int], dict[str, str]]] = []
    pending_nodes: list[tuple[int, float, float]] = []

    for feature in features:
        geom = feature.get("geometry", {})
        props = feature.get("properties", {})

        if geom.get("type") != "LineString":
            skipped += 1
            continue

        coords = geom.get("coordinates", [])  # [[lon, lat], ...]
        if len(coords) < 2:
            skipped += 1
            continue

        feat_type = props.get("type", "")

        tags: dict[str, str] = dict(TYPE_TAGS.get(feat_type, FALLBACK_TAGS))
        tags["source"] = "sofiaplan"
        if feat_type:
            tags["sofiaplan:type"] = feat_type
        if props.get("name"):
            tags["name"] = str(props["name"])
        if props.get("surface"):
            tags["surface"] = str(props["surface"])
        if props.get("posoka") == "Еднопосочна":
            tags["oneway:bicycle"] = "yes"
        if props.get("length"):
            tags["sofiaplan:length"] = str(props["length"])

        node_ids: list[int] = []
        for lon, lat in coords:
            pending_nodes.append((node_id, float(lon), float(lat)))
            node_ids.append(node_id)
            node_id += 1

        pending_ways.append((way_id, node_ids, tags))
        way_id += 1

    # Pass 1: write all nodes
    for nid, lon, lat in pending_nodes:
        writer.add_node(
            mutable.Node(
                id=nid,
                location=osmium.osm.Location(lon, lat),
                tags={},
                version=1,
            )
        )

    # Pass 2: write all ways
    for wid, nids, tags in pending_ways:
        writer.add_way(
            mutable.Way(
                id=wid,
                nodes=nids,
                tags=tags,
                version=1,
            )
        )

    writer.close()

    ways_written = way_id - WAY_ID_START
    nodes_written = node_id - NODE_ID_START
    print(
        f"Converted {ways_written} ways ({nodes_written} nodes) from {geojson_path}"
        f" -> {output_path}"
        + (f"  (skipped {skipped} non-LineString features)" if skipped else "")
    )


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.geojson> <output.osm.pbf>", file=sys.stderr)
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
