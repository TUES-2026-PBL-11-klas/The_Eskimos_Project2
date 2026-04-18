"""SQLAlchemy / GeoAlchemy2 models for bike-routing geospatial data."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import JSON, Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class BikeLaneFeature(Base):
    """One line-like GeoJSON feature from the merged Sofia bike-lane dataset."""

    __tablename__ = "bike_lane_features"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    # MultiLineString accommodates both LineString and MultiLineString inputs
    # (PostGIS lets us treat a LineString as a 1-part multi).
    geometry: Mapped[str] = mapped_column(
        Geometry(geometry_type="MULTILINESTRING", srid=4326, spatial_index=True),
        nullable=False,
    )
    properties: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)


class AvoidPolygon(Base):
    """Pre-defined dangerous zones the router should exclude by default."""

    __tablename__ = "avoid_polygons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    geometry: Mapped[str] = mapped_column(
        Geometry(geometry_type="POLYGON", srid=4326, spatial_index=True),
        nullable=False,
    )
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
