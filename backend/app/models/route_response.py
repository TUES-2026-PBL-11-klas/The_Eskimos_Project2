from pydantic import BaseModel


class ElevationSummary(BaseModel):
    min_elevation: float
    max_elevation: float
    mean_elevation: float


class Maneuver(BaseModel):
    instruction: str
    street_names: list[str]
    length_km: float
    time_seconds: float
    type: int
    begin_shape_index: int
    end_shape_index: int


class RouteResponse(BaseModel):
    distance_km: float
    duration_minutes: float
    polyline: str          # Valhalla encoded polyline6 of the full route shape
    legs: list[dict]       # Raw Valhalla legs for detailed per-leg info
    elevation: ElevationSummary | None = None
    maneuvers: list[Maneuver]
    warnings: list[str]


class ProfileInfo(BaseModel):
    name: str
    display_name: str
    description: str
    bicycle_type: str
    use_roads: float
    use_hills: float
    cycling_speed: float
