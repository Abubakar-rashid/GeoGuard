"""
AI Assistant models for the GeoGuard API
"""

from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    message: str
    context: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    success: bool = True


class SafetyAdviceRequest(BaseModel):
    disaster_type: str
    user_location: Optional[str] = None
    is_emergency: bool = False


class SafetyAdviceResponse(BaseModel):
    advice: str
    disaster_type: str
    is_emergency: bool


class PrecautionsRequest(BaseModel):
    disaster_type: str


class SeasonalTrendsRequest(BaseModel):
    region: str
    month: int
