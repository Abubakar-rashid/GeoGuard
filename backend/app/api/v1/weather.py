"""
Weather API endpoints
"""

from fastapi import APIRouter, Query, HTTPException
from app.models.weather import WeatherResponse
from app.services.weather_service import weather_service

router = APIRouter()


@router.get("/", response_model=WeatherResponse)
async def get_weather(
    latitude: float = Query(..., description="Location latitude"),
    longitude: float = Query(..., description="Location longitude"),
):
    """Get current weather and alerts for a location"""
    result = await weather_service.get_weather(latitude, longitude)
    if result is None:
        raise HTTPException(status_code=404, detail="Weather data not available")
    return result
