"""
Weather service for fetching weather data from external APIs
"""

import httpx
from datetime import datetime
from typing import List, Optional
from app.models.weather import WeatherAlert, WeatherForecast, WeatherResponse
from app.core.config import settings


class WeatherService:
    def __init__(self):
        self.open_meteo_base_url = settings.open_meteo_base_url
        self.nws_base_url = settings.nws_base_url

    async def get_weather(
        self, latitude: float, longitude: float
    ) -> Optional[WeatherResponse]:
        """Get current weather and alerts for a location"""
        try:
            # Get current weather from Open-Meteo
            current = await self._get_open_meteo_weather(latitude, longitude)

            # Get alerts from NWS (US only) or return empty list
            alerts = await self._get_nws_alerts(latitude, longitude)

            if current:
                return WeatherResponse(current=current, alerts=alerts)
            return None

        except Exception as e:
            print(f"Error fetching weather: {e}")
            return None

    async def _get_open_meteo_weather(
        self, latitude: float, longitude: float
    ) -> Optional[WeatherForecast]:
        """Fetch current weather from Open-Meteo API"""
        try:
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m",
            }

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.open_meteo_base_url}/forecast",
                    params=params,
                    timeout=30.0,
                )
                response.raise_for_status()
                data = response.json()

            current = data.get("current", {})

            weather_code = current.get("weather_code", 0)
            weather_description = self._get_weather_description(weather_code)

            return WeatherForecast(
                latitude=latitude,
                longitude=longitude,
                temperature=current.get("temperature_2m", 0),
                temperature_unit="celsius",
                weather_code=weather_code,
                weather_description=weather_description,
                wind_speed=current.get("wind_speed_10m", 0),
                wind_direction=current.get("wind_direction_10m", 0),
                humidity=current.get("relative_humidity_2m", 0),
                timestamp=datetime.now(),
            )

        except Exception as e:
            print(f"Error fetching Open-Meteo weather: {e}")
            return None

    async def _get_nws_alerts(
        self, latitude: float, longitude: float
    ) -> List[WeatherAlert]:
        """Fetch weather alerts from NWS API (US only)"""
        try:
            # NWS API works for US locations
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.nws_base_url}/alerts/active",
                    params={"point": f"{latitude},{longitude}"},
                    headers={"User-Agent": "GeoGuard/1.0"},
                    timeout=30.0,
                )

                if response.status_code != 200:
                    return []

                data = response.json()

            alerts = []
            for feature in data.get("features", []):
                props = feature.get("properties", {})
                alerts.append(
                    WeatherAlert(
                        id=props.get("id", ""),
                        event=props.get("event", ""),
                        headline=props.get("headline", ""),
                        description=props.get("description", ""),
                        severity=props.get("severity", "Unknown"),
                        urgency=props.get("urgency", "Unknown"),
                        areas=props.get("areaDesc", "").split("; "),
                        effective=datetime.fromisoformat(
                            props.get("effective", datetime.now().isoformat()).replace("Z", "+00:00")
                        ),
                        expires=datetime.fromisoformat(
                            props.get("expires", datetime.now().isoformat()).replace("Z", "+00:00")
                        ),
                    )
                )
            return alerts

        except Exception as e:
            print(f"Error fetching NWS alerts: {e}")
            return []

    def _get_weather_description(self, code: int) -> str:
        """Convert WMO weather code to description"""
        descriptions = {
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Fog",
            48: "Depositing rime fog",
            51: "Light drizzle",
            53: "Moderate drizzle",
            55: "Dense drizzle",
            61: "Slight rain",
            63: "Moderate rain",
            65: "Heavy rain",
            71: "Slight snow fall",
            73: "Moderate snow fall",
            75: "Heavy snow fall",
            80: "Slight rain showers",
            81: "Moderate rain showers",
            82: "Violent rain showers",
            85: "Slight snow showers",
            86: "Heavy snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with slight hail",
            99: "Thunderstorm with heavy hail",
        }
        return descriptions.get(code, "Unknown")


# Singleton instance
weather_service = WeatherService()
