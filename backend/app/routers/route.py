from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models.route_request import RouteRequest
from app.models.route_response import ProfileInfo, RouteResponse
from app.profiles.bicycle import PROFILES
from app.services.valhalla_client import get_route

router = APIRouter(tags=["routing"])


@router.post("/route", response_model=RouteResponse)
async def route(
    request: Request,
    body: RouteRequest,
    session: AsyncSession = Depends(get_session),
):
    return await get_route(request.app.state.http_client, body, session=session)


@router.get("/profiles", response_model=list[ProfileInfo])
async def list_profiles():
    return [
        ProfileInfo(
            name=profile.name,
            display_name=profile.display_name,
            description=profile.description,
            bicycle_type=profile.bicycle_type,
            use_roads=profile.use_roads,
            use_hills=profile.use_hills,
            cycling_speed=profile.cycling_speed,
        )
        for profile in PROFILES.values()
    ]
