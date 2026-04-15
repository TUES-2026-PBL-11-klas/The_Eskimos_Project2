from fastapi import APIRouter, Request

from app.services.valhalla_client import check_valhalla_status

router = APIRouter(tags=["health"])


@router.get("/health")
async def health(request: Request):
    valhalla_status = await check_valhalla_status(request.app.state.http_client)
    return {"status": "ok", "valhalla": valhalla_status}
