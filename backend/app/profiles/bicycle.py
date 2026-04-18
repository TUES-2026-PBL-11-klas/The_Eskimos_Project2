"""Bicycle routing profiles — plain data, no abstraction.

Each profile is a frozen dataclass holding the Valhalla costing options for a
bicycle type. Add a new profile by adding a BicycleProfile entry to PROFILES.
"""

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class BicycleProfile:
    name: str
    display_name: str
    description: str
    bicycle_type: str
    cycling_speed: float
    use_roads: float
    use_hills: float
    avoid_bad_surfaces: float
    use_ferry: float = 0.0
    costing: str = "bicycle"

    def costing_options(self) -> dict[str, Any]:
        return {
            "bicycle": {
                "bicycle_type": self.bicycle_type,
                "cycling_speed": self.cycling_speed,
                "use_roads": self.use_roads,
                "use_hills": self.use_hills,
                "avoid_bad_surfaces": self.avoid_bad_surfaces,
                "use_ferry": self.use_ferry,
            }
        }


PROFILES: dict[str, BicycleProfile] = {
    p.name: p
    for p in [
        BicycleProfile(
            name="city_bike",
            display_name="Градски велосипед",
            description=(
                "Предпочита велоалеи и тихи улици. Избягва натоварен трафик и "
                "стръмни участъци."
            ),
            bicycle_type="Hybrid",
            cycling_speed=18.0,
            use_roads=0.1,
            use_hills=0.3,
            avoid_bad_surfaces=0.6,
        ),
        BicycleProfile(
            name="mountain_bike",
            display_name="Планински велосипед",
            description=(
                "Толерира пътища и стръмни участъци. Подходящ за офроуд маршрути."
            ),
            bicycle_type="Mountain",
            cycling_speed=20.0,
            use_roads=0.4,
            use_hills=0.8,
            avoid_bad_surfaces=0.1,
        ),
        BicycleProfile(
            name="electric_bike",
            display_name="Електрически велосипед",
            description=(
                "Моторът компенсира наклони. Предпочита равни маршрути с "
                "умерено натоварване."
            ),
            bicycle_type="Hybrid",
            cycling_speed=25.0,
            use_roads=0.3,
            use_hills=0.0,
            avoid_bad_surfaces=0.4,
        ),
    ]
}

DEFAULT_PROFILE = "city_bike"
