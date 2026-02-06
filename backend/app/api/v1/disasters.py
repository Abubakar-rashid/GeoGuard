"""
Disasters API endpoints
"""

from fastapi import APIRouter, Query
from typing import List, Optional
from app.models.disaster import Disaster, LocationRequest
from app.services.disaster_service import disaster_service

router = APIRouter()


@router.get("/", response_model=List[Disaster])
async def get_all_disasters(
    latitude: Optional[float] = Query(None, description="User's latitude"),
    longitude: Optional[float] = Query(None, description="User's longitude"),
    radius_km: float = Query(500, description="Search radius in kilometers"),
):
    """Get all disasters (earthquakes, floods, weather alerts)"""
    return await disaster_service.get_all_disasters(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
    )


@router.get("/earthquakes", response_model=List[Disaster])
async def get_earthquakes(
    latitude: Optional[float] = Query(None, description="User's latitude"),
    longitude: Optional[float] = Query(None, description="User's longitude"),
    radius_km: float = Query(500, description="Search radius in kilometers"),
    min_magnitude: float = Query(2.5, description="Minimum earthquake magnitude"),
    limit: int = Query(50, description="Maximum number of results"),
):
    """Get earthquakes from USGS"""
    if latitude is not None and longitude is not None:
        return await disaster_service.get_earthquakes_near_location(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            min_magnitude=min_magnitude,
        )
    return await disaster_service.get_earthquakes(
        min_magnitude=min_magnitude,
        limit=limit,
    )


@router.get("/floods", response_model=List[Disaster])
async def get_floods(
    latitude: Optional[float] = Query(None, description="User's latitude"),
    longitude: Optional[float] = Query(None, description="User's longitude"),
):
    """Get flood warnings"""
    return await disaster_service.get_flood_warnings(
        latitude=latitude,
        longitude=longitude,
    )


@router.get("/weather-alerts", response_model=List[Disaster])
async def get_weather_alerts(
    latitude: Optional[float] = Query(None, description="User's latitude"),
    longitude: Optional[float] = Query(None, description="User's longitude"),
):
    """Get weather alerts as disasters"""
    return await disaster_service.get_weather_alerts(
        latitude=latitude,
        longitude=longitude,
    )


@router.post("/nearby", response_model=List[Disaster])
async def get_nearby_disasters(location: LocationRequest):
    """Get disasters near a specific location"""
    return await disaster_service.get_all_disasters(
        latitude=location.latitude,
        longitude=location.longitude,
        radius_km=500,
    )
