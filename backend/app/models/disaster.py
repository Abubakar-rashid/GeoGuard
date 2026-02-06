"""
Disaster models for the GeoGuard API
"""

from pydantic import BaseModel
from enum import Enum
from datetime import datetime
from typing import Optional


class DisasterType(str, Enum):
    earthquake = "earthquake"
    flood = "flood"
    weather = "weather"


class SeverityLevel(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class Disaster(BaseModel):
    id: str
    type: DisasterType
    title: str
    description: str
    latitude: float
    longitude: float
    magnitude: float
    severity: SeverityLevel
    radius_km: float
    timestamp: datetime
    location: Optional[str] = None
    distance_from_user: Optional[float] = None

    class Config:
        from_attributes = True


class DisasterQueryParams(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: float = 500
    min_magnitude: float = 2.5
    limit: int = 50


class LocationRequest(BaseModel):
    latitude: float
    longitude: float
