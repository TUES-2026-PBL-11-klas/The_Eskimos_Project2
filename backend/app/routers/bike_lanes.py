import json
from pathlib import Path

from fastapi import APIRouter, HTTPException

from app.config import settings

router = APIRouter(tags=["bike-lanes"])

_ASSETS = Path(settings.assets_dir)


def _load_geojson(filename: str) -> dict:
    path = _ASSETS / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"{filename} not found in assets")
    with path.open(encoding="utf-8") as f:
        return json.load(f)


@router.get("/bike-lanes")
async def get_bike_lanes():
    return _load_geojson("velo_sofia_merged.geojson")


