"""
Survival guide models for the GeoGuard API
"""

from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class SurvivalStep(BaseModel):
    order: int
    title: str
    description: str
    image_asset: Optional[str] = None


class SurvivalGuide(BaseModel):
    id: str
    title: str
    category: str
    icon_asset: str
    essential_steps: int
    is_available_offline: bool = False
    steps: List[SurvivalStep]
    last_updated: Optional[datetime] = None


class SurvivalGuideList(BaseModel):
    guides: List[SurvivalGuide]
    total: int
