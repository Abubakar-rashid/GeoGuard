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
    radius_km: float = Query(1000, description="Search radius in kilometers (default 1000 km)"),
    min_magnitude: float = Query(4.0, description="Minimum earthquake magnitude"),
    days: int = Query(7, description="Number of days to look back"),
):
    """
    Check earthquake risks near the user's location within a 1000 km radius.
    Returns recent earthquakes with magnitude >= min_magnitude within the specified radius.
    If no earthquakes are found, returns an empty list with a threat_detected: false flag.
    """
    earthquakes = await disaster_service.check_earthquake_risk(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        min_magnitude=min_magnitude,
        days=days,
    )
    threat_detected = len(earthquakes) > 0
    return {
        "user_location": {"latitude": latitude, "longitude": longitude},
        "radius_km": radius_km,
        "min_magnitude": min_magnitude,
        "days_checked": days,
        "earthquake_count": len(earthquakes),
        "threat_detected": threat_detected,
        "message": f"Found {len(earthquakes)} earthquake(s) within {radius_km} km" if threat_detected else "No significant earthquake risk identified within 1000 km",
        "earthquakes": earthquakes,
    }


@router.get("/check-flood-risk")
async def check_flood_risk(
    latitude: float = Query(..., description="User's latitude"),
    longitude: float = Query(..., description="User's longitude"),
):
    """
    Check flood risk for the user's location using the Open-Meteo Flood API.
    Returns daily river discharge data with LOW / MODERATE / HIGH risk classifications.
    """
    import httpx

    url = "https://flood-api.open-meteo.com/v1/flood"
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "daily": ["river_discharge", "river_discharge_mean", "river_discharge_max"],
        "timezone": "auto",
    }

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        return {
            "user_location": {"latitude": latitude, "longitude": longitude},
            "error": str(e),
            "daily": [],
            "overall_risk": "UNKNOWN",
        }

    daily = data.get("daily", {})
    dates = daily.get("time", [])
    discharge = daily.get("river_discharge", [])
    discharge_mean = daily.get("river_discharge_mean", [])
    discharge_max = daily.get("river_discharge_max", [])

    results = []
    risk_counts = {"LOW": 0, "MODERATE": 0, "HIGH": 0}

    for i in range(len(dates)):
        current = discharge[i] if i < len(discharge) else None
        mean = discharge_mean[i] if i < len(discharge_mean) else None

        if current is None or mean is None:
            risk = "UNKNOWN"
            ratio = None
        else:
            ratio = current / (mean + 1e-6)
            if ratio > 1.5:
                risk = "HIGH"
            elif ratio > 1.2:
                risk = "MODERATE"
            else:
                risk = "LOW"
            risk_counts[risk] += 1

        results.append(
            {
                "date": dates[i],
                "river_discharge": current,
                "river_discharge_mean": mean,
                "river_discharge_max": discharge_max[i] if i < len(discharge_max) else None,
                "ratio": round(ratio, 4) if ratio is not None else None,
                "risk": risk,
            }
        )

    # Overall risk = worst seen
    if risk_counts["HIGH"] > 0:
        overall_risk = "HIGH"
    elif risk_counts["MODERATE"] > 0:
        overall_risk = "MODERATE"
    else:
        overall_risk = "LOW"

    return {
        "user_location": {"latitude": latitude, "longitude": longitude},
        "overall_risk": overall_risk,
        "risk_counts": risk_counts,
        "daily": results,
    }


@router.get("/check-weather-risk")
async def check_weather_risk(
    latitude: float = Query(..., description="User's latitude"),
    longitude: float = Query(..., description="User's longitude"),
):
    """
    Check weather risk using the Tomorrow.io Forecast API.
    Returns a 5-day daily forecast with risk classification per day.
    Risk levels: LOW | WINDY | HEAT | MODERATE | HIGH
    """
    import httpx
    from app.core.config import settings

    api_key = settings.tomorrow_api_key
    if not api_key or api_key == "YOUR_TOMORROW_API_KEY":
        return {
            "error": "Tomorrow.io API key not configured. Set TOMORROW_API_KEY in backend/.env",
            "user_location": {"latitude": latitude, "longitude": longitude},
            "overall_risk": "UNKNOWN",
            "daily": [],
        }

    url = "https://api.tomorrow.io/v4/weather/forecast"
    params = {
        "location": f"{latitude},{longitude}",
        "apikey": api_key,
        "timesteps": "1d",
        "fields": [
            "temperatureMax",
            "temperatureMin",
            "temperatureAvg",
            "humidityAvg",
            "rainAccumulationSum",
            "windSpeedAvg",
            "windGustMax",
            "uvIndexMax",
            "weatherCodeAvg",
            "precipitationProbabilityAvg",
        ],
    }

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        return {
            "error": str(e),
            "user_location": {"latitude": latitude, "longitude": longitude},
            "overall_risk": "UNKNOWN",
            "daily": [],
        }

    timelines = data.get("timelines", {}).get("daily", [])
    risk_priority = {"LOW": 0, "WINDY": 1, "HEAT": 2, "MODERATE": 3, "HIGH": 4}
    results = []
    overall_risk = "LOW"

    for day in timelines:
        date = day.get("time", "")[:10]
        v = day.get("values", {})

        rain = v.get("rainAccumulationSum", 0) or 0
        wind = v.get("windSpeedAvg", 0) or 0
        gust = v.get("windGustMax", 0) or 0
        temp_max = v.get("temperatureMax", 0) or 0
        temp_min = v.get("temperatureMin", 0) or 0
        temp_avg = v.get("temperatureAvg", 0) or 0
        humidity = v.get("humidityAvg", 0) or 0
        uv = v.get("uvIndexMax", 0) or 0
        precip_prob = v.get("precipitationProbabilityAvg", 0) or 0
        weather_code = v.get("weatherCodeAvg", 0) or 0

        # Risk classification logic (matches the Python script thresholds)
        if rain > 20:
            risk = "HIGH"
        elif rain > 5:
            risk = "MODERATE"
        elif wind > 10:
            risk = "WINDY"
        elif temp_max > 40:
            risk = "HEAT"
        else:
            risk = "LOW"

        if risk_priority.get(risk, 0) > risk_priority.get(overall_risk, 0):
            overall_risk = risk

        results.append({
            "date": date,
            "temperature_max": round(temp_max, 1),
            "temperature_min": round(temp_min, 1),
            "temperature_avg": round(temp_avg, 1),
            "humidity_avg": round(humidity),
            "rain_mm": round(rain, 1),
            "wind_speed_avg": round(wind, 1),
            "wind_gust_max": round(gust, 1),
            "uv_index_max": round(uv),
            "precip_probability": round(precip_prob),
            "weather_code": weather_code,
            "risk": risk,
        })

    return {
        "user_location": {"latitude": latitude, "longitude": longitude},
        "overall_risk": overall_risk,
        "daily": results,
    }
