from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator

from app.profiles.bicycle import DEFAULT_PROFILE, PROFILES

# Generous Sofia bounding box with margin; requests outside are rejected.
_SOFIA_LAT_MIN = 42.55
_SOFIA_LAT_MAX = 42.85
_SOFIA_LON_MIN = 23.10
_SOFIA_LON_MAX = 23.60

_MAX_AVOID_POLYGONS = 20
_MAX_VERTICES_PER_POLYGON = 100
_MAX_TOTAL_VERTICES = 1000


class Coordinate(BaseModel):
    lat: float = Field(..., ge=_SOFIA_LAT_MIN, le=_SOFIA_LAT_MAX, description="Latitude")
    lon: float = Field(..., ge=_SOFIA_LON_MIN, le=_SOFIA_LON_MAX, description="Longitude")


class RouteRequest(BaseModel):
    start: Coordinate = Field(..., description="Start location")
    end: Coordinate = Field(..., description="End location")
    profile: str = Field(
        DEFAULT_PROFILE,
        description=f"Routing profile. One of: {', '.join(PROFILES)}",
    )
    include_elevation: bool = Field(
        True, description="Include elevation data in response (30m interval)"
    )
    avoid_dangerous: bool = Field(
        True, description="Avoid pre-defined dangerous zones (Orlov Most, etc.)"
    )
    extra_avoid_polygons: list[list[Coordinate]] = Field(
        default_factory=list,
        max_length=_MAX_AVOID_POLYGONS,
        description="Additional user-supplied polygons to avoid",
    )
    language: Literal["bg-BG", "en-US"] = Field(
        "bg-BG", description="Language for turn instructions"
    )

    @field_validator("profile")
    @classmethod
    def profile_must_exist(cls, v: str) -> str:
        if v not in PROFILES:
            raise ValueError(f"Unknown profile '{v}'. Valid: {list(PROFILES)}")
        return v

    @model_validator(mode="after")
    def check_polygon_sizes(self) -> "RouteRequest":
        total = 0
        for i, poly in enumerate(self.extra_avoid_polygons):
            if len(poly) > _MAX_VERTICES_PER_POLYGON:
                raise ValueError(
                    f"Polygon {i} has {len(poly)} vertices "
                    f"(max {_MAX_VERTICES_PER_POLYGON})"
                )
            total += len(poly)
        if total > _MAX_TOTAL_VERTICES:
            raise ValueError(
                f"Total vertex count {total} exceeds max {_MAX_TOTAL_VERTICES}"
            )
        return self
