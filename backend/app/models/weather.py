"""
Weather models for the GeoGuard API
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class WeatherAlert(BaseModel):
    id: str
    event: str
    headline: str
    description: str
    severity: str
    urgency: str
    areas: List[str]
    effective: datetime
    expires: datetime


class WeatherForecast(BaseModel):
    latitude: float
    longitude: float
    temperature: float
    temperature_unit: str = "celsius"
    weather_code: int
    weather_description: str
    wind_speed: float
    wind_direction: int
    humidity: int
    timestamp: datetime


class WeatherResponse(BaseModel):
    current: WeatherForecast
    alerts: List[WeatherAlert] = []
