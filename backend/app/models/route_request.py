from pydantic import BaseModel, Field, field_validator

from app.profiles.bicycle import DEFAULT_PROFILE, PROFILES


class Coordinate(BaseModel):
    lat: float = Field(..., ge=-90, le=90, description="Latitude")
    lon: float = Field(..., ge=-180, le=180, description="Longitude")


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
        description="Additional user-supplied polygons to avoid",
    )
    language: str = Field("bg-BG", description="Language for turn instructions")

    @field_validator("profile")
    @classmethod
    def profile_must_exist(cls, v: str) -> str:
        if v not in PROFILES:
            raise ValueError(f"Unknown profile '{v}'. Valid: {list(PROFILES)}")
        return v
