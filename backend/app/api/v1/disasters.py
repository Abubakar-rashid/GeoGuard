"""
Disasters API endpoints
"""

from fastapi import APIRouter, Query, Path
from typing import List, Optional
from app.models.disaster import Disaster, LocationRequest
from app.models.country_eda import CountryEDA
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


@router.get("/country/{country_name}/eda", response_model=CountryEDA)
async def get_country_eda(
    country_name: str = Path(..., description="Name of the country"),
):
    """
    Get Exploratory Data Analysis (EDA) overview for a specific country.
    Returns comprehensive disaster statistics, risk assessment, seasonal patterns,
    and safety recommendations for the country.
    """
    return await disaster_service.get_country_eda(country_name=country_name)


@router.get("/countries/search", response_model=List[str])
async def search_countries(
    query: str = Query(..., min_length=2, description="Search query for country name"),
):
    """
    Search for countries by name.
    Returns a list of matching country names.
    """
    return await disaster_service.search_countries(query=query)


@router.get("/check-risk")
async def check_earthquake_risk(
    latitude: float = Query(..., description="User's latitude"),
    longitude: float = Query(..., description="User's longitude"),
    radius_km: float = Query(500, description="Search radius in kilometers"),
    min_magnitude: float = Query(4.0, description="Minimum earthquake magnitude"),
    days: int = Query(7, description="Number of days to look back"),
):
    """
    Check earthquake risks near the user's location.
    Returns recent earthquakes with magnitude >= min_magnitude within the specified radius.
    """
    earthquakes = await disaster_service.check_earthquake_risk(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        min_magnitude=min_magnitude,
        days=days,
    )
    return {
        "user_location": {"latitude": latitude, "longitude": longitude},
        "radius_km": radius_km,
        "min_magnitude": min_magnitude,
        "days_checked": days,
        "earthquake_count": len(earthquakes),
        "earthquakes": earthquakes,
    }

