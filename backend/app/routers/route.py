from fastapi import APIRouter, Request

from app.models.route_request import RouteRequest
from app.models.route_response import ProfileInfo, RouteResponse
from app.profiles.bicycle import PROFILES
from app.services.valhalla_client import get_route

router = APIRouter(tags=["routing"])


@router.post("/route", response_model=RouteResponse)
async def route(request: Request, body: RouteRequest):
    return await get_route(request.app.state.http_client, body)


@router.get("/profiles", response_model=list[ProfileInfo])
async def list_profiles():
    result = []
    for profile in PROFILES.values():
        opts = profile.costing_options()["bicycle"]
        result.append(
            ProfileInfo(
                name=profile.name(),
                display_name=profile.display_name(),
                description=profile.description(),
                bicycle_type=opts["bicycle_type"],
                use_roads=opts["use_roads"],
                use_hills=opts["use_hills"],
                cycling_speed=opts["cycling_speed"],
            )
        )
    return result
