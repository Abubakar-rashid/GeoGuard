"""
AI Assistant API endpoints
"""

from fastapi import APIRouter
from app.models.ai_assistant import (
    ChatRequest,
    ChatResponse,
    SafetyAdviceRequest,
    SafetyAdviceResponse,
    PrecautionsRequest,
    SeasonalTrendsRequest,
)
from app.services.ai_assistant_service import ai_assistant_service

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat with AI assistant about disaster safety"""
    response = await ai_assistant_service.chat(request.message)
    return ChatResponse(response=response, success=True)


@router.post("/safety-advice", response_model=SafetyAdviceResponse)
async def get_safety_advice(request: SafetyAdviceRequest):
    """Get safety advice for a specific disaster type"""
    advice = await ai_assistant_service.get_safety_advice(
        disaster_type=request.disaster_type,
        user_location=request.user_location,
        is_emergency=request.is_emergency,
    )
    return SafetyAdviceResponse(
        advice=advice,
        disaster_type=request.disaster_type,
        is_emergency=request.is_emergency,
    )


@router.post("/precautions")
async def get_precautions(request: PrecautionsRequest):
    """Get precautions for a specific disaster type"""
    precautions = await ai_assistant_service.get_precautions(request.disaster_type)
    return {"disaster_type": request.disaster_type, "precautions": precautions}


@router.post("/seasonal-trends")
async def analyze_seasonal_trends(request: SeasonalTrendsRequest):
    """Analyze seasonal disaster trends for a region"""
    analysis = await ai_assistant_service.analyze_seasonal_trends(
        region=request.region,
        month=request.month,
    )
    return {
        "region": request.region,
        "month": request.month,
        "analysis": analysis,
    }
