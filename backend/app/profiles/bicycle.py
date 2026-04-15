"""Bicycle routing profiles — Strategy Pattern.
Each profile encapsulates Valhalla costing options for a specific
bicycle type. Add new profiles by subclassing BicycleProfile and
registering them in PROFILES.
"""

from abc import ABC, abstractmethod
from typing import Any


class BicycleProfile(ABC):

    @abstractmethod
    def name(self) -> str: ...

    @abstractmethod
    def display_name(self) -> str: ...

    @abstractmethod
    def description(self) -> str: ...

    @abstractmethod
    def costing_options(self) -> dict[str, Any]: ...

    def costing(self) -> str:
        return "bicycle"


class CityBikeProfile(BicycleProfile):
    def name(self) -> str:
        return "city_bike"

    def display_name(self) -> str:
        return "Градски велосипед"

    def description(self) -> str:
        return "Предпочита велоалеи и тихи улици. Избягва натоварен трафик и стръмни участъци."

    def costing_options(self) -> dict[str, Any]:
        return {
            "bicycle": {
                "bicycle_type": "Hybrid",
                "cycling_speed": 18.0,
                "use_roads": 0.1,
                "use_hills": 0.3,
                "avoid_bad_surfaces": 0.6,
                "use_ferry": 0.0,
            }
        }


class MountainBikeProfile(BicycleProfile):
    def name(self) -> str:
        return "mountain_bike"

    def display_name(self) -> str:
        return "Планински велосипед"

    def description(self) -> str:
        return "Толерира пътища и стръмни участъци. Подходящ за офроуд маршрути."

    def costing_options(self) -> dict[str, Any]:
        return {
            "bicycle": {
                "bicycle_type": "Mountain",
                "cycling_speed": 20.0,
                "use_roads": 0.4,
                "use_hills": 0.8,
                "avoid_bad_surfaces": 0.1,
                "use_ferry": 0.0,
            }
        }


class ElectricBikeProfile(BicycleProfile):
    def name(self) -> str:
        return "electric_bike"

    def display_name(self) -> str:
        return "Електрически велосипед"

    def description(self) -> str:
        return "Моторът компенсира наклони. Предпочита равни маршрути с умерено натоварване."

    def costing_options(self) -> dict[str, Any]:
        return {
            "bicycle": {
                "bicycle_type": "Hybrid",
                "cycling_speed": 25.0,
                "use_roads": 0.3,
                "use_hills": 0.0,
                "avoid_bad_surfaces": 0.4,
                "use_ferry": 0.0,
            }
        }


PROFILES: dict[str, BicycleProfile] = {
    p.name(): p
    for p in [
        CityBikeProfile(),
        MountainBikeProfile(),
        ElectricBikeProfile(),
    ]
}

DEFAULT_PROFILE = "city_bike"
