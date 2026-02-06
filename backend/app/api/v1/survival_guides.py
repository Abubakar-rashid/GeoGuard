"""
Survival Guides API endpoints
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.models.survival_guide import SurvivalGuide, SurvivalGuideList
from app.services.survival_guide_service import survival_guide_service

router = APIRouter()


@router.get("/", response_model=SurvivalGuideList)
async def get_all_guides(
    category: Optional[str] = Query(None, description="Filter by category"),
):
    """Get all survival guides"""
    if category:
        guides = survival_guide_service.get_guides_by_category(category)
    else:
        guides = survival_guide_service.get_all_guides()
    return SurvivalGuideList(guides=guides, total=len(guides))


@router.get("/{guide_id}", response_model=SurvivalGuide)
async def get_guide(guide_id: str):
    """Get a specific survival guide by ID"""
    guide = survival_guide_service.get_guide_by_id(guide_id)
    if guide is None:
        raise HTTPException(status_code=404, detail="Guide not found")
    return guide
