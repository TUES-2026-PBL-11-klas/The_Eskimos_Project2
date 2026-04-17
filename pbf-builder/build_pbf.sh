#!/usr/bin/env bash
# Downloads Geofabrik Bulgaria PBF, converts GeoJSON bike ways to OSM format,
# and merges them into a single PBF for Valhalla tile building.
set -euo pipefail

MERGED_PBF=/data/merged-bulgaria.osm.pbf
TMP_DIR=/data/tmp
GEOJSON=/data/geojson/velo_sofia_merged.geojson
GEOFABRIK_URL="https://download.geofabrik.de/europe/bulgaria-latest.osm.pbf"

# Copy custom Valhalla config into the shared volume so Valhalla picks it up.
# The gis-ops image's configure script preserves existing values and only adds
# missing defaults, so our overrides (e.g. max_exclude_polygons_length) survive.
if [ -f /app/valhalla.json ]; then
    cp /app/valhalla.json /data/valhalla.json
    echo "[pbf-builder] Copied custom valhalla.json to /data/valhalla.json"
fi

# Skip if already built (persisted in named volume)
if [ -f "$MERGED_PBF" ]; then
    echo "[pbf-builder] Merged PBF already exists at $MERGED_PBF, skipping build."
    exit 0
fi

echo "[pbf-builder] Starting PBF build pipeline..."
mkdir -p "$TMP_DIR"

# 1. Download Geofabrik Bulgaria PBF
GEOFABRIK_PBF="$TMP_DIR/bulgaria-latest.osm.pbf"
if [ -f "$GEOFABRIK_PBF" ]; then
    echo "[pbf-builder] Geofabrik PBF already downloaded, skipping."
else
    echo "[pbf-builder] Downloading bulgaria-latest.osm.pbf from Geofabrik (~153 MB)..."
    wget --progress=dot:giga \
         --tries=3 \
         --timeout=120 \
         -O "$GEOFABRIK_PBF" \
         "$GEOFABRIK_URL"
    echo "[pbf-builder] Download complete."
fi

# 2. Convert GeoJSON bike ways to OSM PBF
BIKE_WAYS_PBF="$TMP_DIR/bike_ways.osm.pbf"
echo "[pbf-builder] Converting $GEOJSON -> $BIKE_WAYS_PBF ..."
python3 /app/geojson_to_osm.py "$GEOJSON" "$BIKE_WAYS_PBF"

# 3. Merge Geofabrik PBF with bike ways PBF
echo "[pbf-builder] Merging PBF files with osmium..."
osmium merge \
    "$GEOFABRIK_PBF" \
    "$BIKE_WAYS_PBF" \
    -o "$MERGED_PBF" \
    --overwrite \
    --progress

echo "[pbf-builder] Merged PBF ready: $MERGED_PBF"
echo "[pbf-builder] Done."
