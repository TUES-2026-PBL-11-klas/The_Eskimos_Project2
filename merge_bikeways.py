import json
import os

ASSETS_DIR     = os.path.join(os.path.dirname(__file__), "assets")
OSM_FILE       = os.path.join(ASSETS_DIR, "velo_sofia_OSM.geojson")
SOFIAPLAN_FILE = os.path.join(ASSETS_DIR, "velo_sofia_sofiaplan.geojson")
OUTPUT_FILE    = os.path.join(ASSETS_DIR, "velo_sofia_merged.geojson")


def load_geojson(filepath: str, source_label: str) -> list:
    """Load a GeoJSON file and tag every feature with its source."""
    print(f"Loading '{source_label}' from {filepath} ...")

    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    features = data.get("features", [])

    for feature in features:
        if feature.get("properties") is None:
            feature["properties"] = {}
        feature["properties"]["source"] = source_label

    print(f"  -> {len(features)} features loaded")
    return features


def merge(features_list: list) -> dict:
    """Combine multiple feature lists into one FeatureCollection."""
    all_features = []
    for features in features_list:
        all_features.extend(features)

    return {
        "type": "FeatureCollection",
        "features": all_features
    }


def save_geojson(data: dict, filepath: str):
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    size_kb = os.path.getsize(filepath) / 1024
    print(f"\nSaved -> '{filepath}'")
    print(f"   Total features : {len(data['features'])}")
    print(f"   File size      : {size_kb:.1f} KB")


def main():
    for path in (OSM_FILE, SOFIAPLAN_FILE):
        if not os.path.exists(path):
            print(f"ERROR: File not found: {path}")
            print("Make sure the script is in the repo root and the assets folder contains:")
            print("  velo_sofia_OSM.geojson")
            print("  velo_sofia_sofiaplan.geojson")
            return

    osm_features       = load_geojson(OSM_FILE,       source_label="osm")
    sofiaplan_features = load_geojson(SOFIAPLAN_FILE, source_label="sofiaplan")

    merged = merge([osm_features, sofiaplan_features])

    print(f"\nBreakdown:")
    print(f"  OSM        : {len(osm_features)} features")
    print(f"  SofiaPlan  : {len(sofiaplan_features)} features")
    print(f"  Total      : {len(merged['features'])} features")

    save_geojson(merged, OUTPUT_FILE)


if __name__ == "__main__":
    main()