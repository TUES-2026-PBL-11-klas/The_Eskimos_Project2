"""Unit tests for routing profiles."""

import pytest

from app.profiles.bicycle import PROFILES


def test_all_profiles_registered():
    assert "city_bike" in PROFILES
    assert "mountain_bike" in PROFILES
    assert "electric_bike" in PROFILES


def test_city_bike_profile():
    p = PROFILES["city_bike"]
    assert p.name == "city_bike"
    assert p.costing == "bicycle"
    opts = p.costing_options()["bicycle"]
    assert opts["use_roads"] == 0.1
    assert opts["use_hills"] == 0.3
    assert opts["bicycle_type"] == "Hybrid"


def test_mountain_bike_profile():
    p = PROFILES["mountain_bike"]
    opts = p.costing_options()["bicycle"]
    assert opts["use_roads"] == 0.4
    assert opts["use_hills"] == 0.8
    assert opts["bicycle_type"] == "Mountain"


def test_electric_bike_profile():
    p = PROFILES["electric_bike"]
    opts = p.costing_options()["bicycle"]
    assert opts["use_roads"] == 0.3
    assert opts["use_hills"] == 0.0, "Electric bike should ignore hills (motor assist)"
    assert opts["bicycle_type"] == "Hybrid"


def test_city_bike_prefers_bike_lanes_over_mountain():
    city = PROFILES["city_bike"]
    mountain = PROFILES["mountain_bike"]
    assert city.use_roads < mountain.use_roads, "CityBike must avoid roads more"


@pytest.mark.parametrize("profile_name", list(PROFILES))
def test_profile_has_required_keys(profile_name):
    profile = PROFILES[profile_name]
    opts = profile.costing_options()
    assert "bicycle" in opts
    bicycle_opts = opts["bicycle"]
    for key in ("bicycle_type", "use_roads", "use_hills", "cycling_speed"):
        assert key in bicycle_opts, f"Missing key '{key}' in {profile_name}"
    assert 0.0 <= bicycle_opts["use_roads"] <= 1.0
    assert 0.0 <= bicycle_opts["use_hills"] <= 1.0


@pytest.mark.parametrize("profile_name", list(PROFILES))
def test_profile_has_display_info(profile_name):
    profile = PROFILES[profile_name]
    assert profile.display_name
    assert profile.description
