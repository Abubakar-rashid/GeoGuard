"""
Country EDA (Exploratory Data Analysis) models for GeoGuard API
Provides statistical overview of disasters in a specific country
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class DisasterStats(BaseModel):
    """Statistics for a specific disaster type in a country"""
    type: str  # "earthquake", "flood", "weather"
    total_count: int
    average_magnitude: float
    max_magnitude: float
    high_risk_count: int  # Count of high severity events
    medium_risk_count: int
    low_risk_count: int
    recent_count: int  # Events in last 30 days


class RiskAssessment(BaseModel):
    """Overall risk assessment for a country"""
    overall_risk_level: str  # "low", "medium", "high", "critical"
    risk_score: float  # 0-100
    primary_hazard: str  # Most common/dangerous disaster type
    secondary_hazards: List[str]  # Other significant hazards
    last_major_event: Optional[datetime] = None
    days_since_event: Optional[int] = None


class CountrySeasonalRisk(BaseModel):
    """Seasonal risk patterns for a country"""
    season: str  # "spring", "summer", "fall", "winter"
    risk_level: str  # "low", "medium", "high"
    primary_hazards: List[str]
    incident_frequency: int  # Average incidents per month


class CountryEDA(BaseModel):
    """Complete EDA overview for a country"""
    country_name: str
    country_code: str  # ISO 3166-1 alpha-2 code
    
    # Statistical Overview
    latitude: float
    longitude: float
    area_sq_km: float
    population: Optional[int] = None
    
    # Disaster Statistics
    earthquake_stats: DisasterStats
    flood_stats: DisasterStats
    weather_stats: DisasterStats
    
    # Risk Assessment
    risk_assessment: RiskAssessment
    
    # Seasonal Patterns
    seasonal_risks: List[CountrySeasonalRisk]
    
    # Historical Data
    total_disasters_last_year: int
    total_disasters_last_5_years: int
    
    # Trends
    trend_direction: str  # "increasing", "stable", "decreasing"
    trend_percentage: float  # Year-over-year change percentage
    
    # Recommendations
    safety_recommendations: List[str]
    
    # Last Updated
    last_updated: datetime

    class Config:
        from_attributes = True
