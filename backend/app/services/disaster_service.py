"""
Disaster service for fetching disaster data from external APIs
"""

import httpx
from datetime import datetime, timedelta
from typing import List, Optional
from app.models.disaster import Disaster, DisasterType, SeverityLevel
from app.core.config import settings


class DisasterService:
    def __init__(self):
        self.usgs_base_url = settings.usgs_base_url
        self.gdacs_base_url = settings.gdacs_base_url

    async def get_earthquakes(
        self,
        min_latitude: Optional[float] = None,
        max_latitude: Optional[float] = None,
        min_longitude: Optional[float] = None,
        max_longitude: Optional[float] = None,
        min_magnitude: float = 2.5,
        limit: int = 50,
    ) -> List[Disaster]:
        """Fetch earthquakes from USGS API"""
        try:
            now = datetime.now()
            start_time = now - timedelta(days=7)

            params = {
                "format": "geojson",
                "starttime": start_time.strftime("%Y-%m-%d"),
                "endtime": now.strftime("%Y-%m-%d"),
                "minmagnitude": str(min_magnitude),
                "limit": str(limit),
                "orderby": "time",
            }

            if min_latitude is not None:
                params["minlatitude"] = str(min_latitude)
            if max_latitude is not None:
                params["maxlatitude"] = str(max_latitude)
            if min_longitude is not None:
                params["minlongitude"] = str(min_longitude)
            if max_longitude is not None:
                params["maxlongitude"] = str(max_longitude)

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.usgs_base_url}/query",
                    params=params,
                    timeout=30.0,
                )
                response.raise_for_status()
                data = response.json()

            features = data.get("features", [])
            return [self._parse_usgs_earthquake(f) for f in features]

        except Exception as e:
            print(f"Error fetching earthquakes: {e}")
            return []

    async def get_earthquakes_near_location(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 500,
        min_magnitude: float = 2.5,
    ) -> List[Disaster]:
        """Fetch earthquakes near a specific location"""
        try:
            now = datetime.now()
            start_time = now - timedelta(days=30)

            params = {
                "format": "geojson",
                "starttime": start_time.strftime("%Y-%m-%d"),
                "endtime": now.strftime("%Y-%m-%d"),
                "latitude": str(latitude),
                "longitude": str(longitude),
                "maxradiuskm": str(radius_km),
                "minmagnitude": str(min_magnitude),
                "orderby": "time",
            }

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.usgs_base_url}/query",
                    params=params,
                    timeout=30.0,
                )
                response.raise_for_status()
                data = response.json()

            features = data.get("features", [])
            disasters = [self._parse_usgs_earthquake(f) for f in features]

            # Calculate distance from user for each disaster
            for disaster in disasters:
                distance = self._calculate_distance(
                    latitude, longitude, disaster.latitude, disaster.longitude
                )
                disaster.distance_from_user = distance

            return disasters

        except Exception as e:
            print(f"Error fetching earthquakes near location: {e}")
            return []

    async def get_flood_warnings(
        self,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> List[Disaster]:
        """Get flood warnings - currently returns mock data"""
        # In production, integrate with GDACS or other flood monitoring APIs
        return self._get_mock_flood_data()

    async def get_weather_alerts(
        self,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> List[Disaster]:
        """Get weather alerts - currently returns mock data"""
        # In production, integrate with NWS or other weather alert APIs
        return self._get_mock_weather_data()

    async def get_all_disasters(
        self,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        radius_km: float = 500,
    ) -> List[Disaster]:
        """Get all types of disasters combined"""
        disasters = []

        # Fetch earthquakes
        if latitude is not None and longitude is not None:
            earthquakes = await self.get_earthquakes_near_location(
                latitude=latitude,
                longitude=longitude,
                radius_km=radius_km,
            )
        else:
            earthquakes = await self.get_earthquakes()
        disasters.extend(earthquakes)

        # Fetch floods and weather
        floods = await self.get_flood_warnings(latitude, longitude)
        weather = await self.get_weather_alerts(latitude, longitude)
        disasters.extend(floods)
        disasters.extend(weather)

        # Sort by timestamp (most recent first)
        disasters.sort(key=lambda d: d.timestamp, reverse=True)
        return disasters

    def _parse_usgs_earthquake(self, feature: dict) -> Disaster:
        """Parse USGS GeoJSON feature to Disaster model"""
        properties = feature.get("properties", {})
        geometry = feature.get("geometry", {})
        coordinates = geometry.get("coordinates", [0, 0, 0])

        mag = float(properties.get("mag", 0) or 0)

        # Determine severity based on magnitude
        if mag >= 6.0:
            severity = SeverityLevel.high
        elif mag >= 4.0:
            severity = SeverityLevel.medium
        else:
            severity = SeverityLevel.low

        # Calculate radius based on magnitude
        radius_km = mag * 20

        timestamp = datetime.fromtimestamp(
            properties.get("time", 0) / 1000
        )

        return Disaster(
            id=feature.get("id", ""),
            type=DisasterType.earthquake,
            title=properties.get("title", "Earthquake"),
            description=properties.get("place", "Unknown location"),
            longitude=float(coordinates[0]),
            latitude=float(coordinates[1]),
            magnitude=mag,
            severity=severity,
            radius_km=radius_km,
            timestamp=timestamp,
            location=properties.get("place"),
        )

    def _calculate_distance(
        self, lat1: float, lon1: float, lat2: float, lon2: float
    ) -> float:
        """Calculate distance between two coordinates in kilometers (Haversine formula)"""
        import math

        R = 6371  # Earth's radius in kilometers

        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)

        a = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    def _get_mock_flood_data(self) -> List[Disaster]:
        """Return mock flood data for demo purposes"""
        return [
            Disaster(
                id="flood_001",
                type=DisasterType.flood,
                title="Flash Flood Warning",
                description="Downtown District",
                latitude=37.7749,
                longitude=-122.4194,
                magnitude=3,
                severity=SeverityLevel.medium,
                radius_km=15,
                timestamp=datetime.now() - timedelta(hours=5),
                location="Downtown District",
            )
        ]

    def _get_mock_weather_data(self) -> List[Disaster]:
        """Return mock weather data for demo purposes"""
        return [
            Disaster(
                id="weather_001",
                type=DisasterType.weather,
                title="Severe Thunderstorm",
                description="Northern Region",
                latitude=37.8749,
                longitude=-122.2594,
                magnitude=2,
                severity=SeverityLevel.medium,
                radius_km=25,
                timestamp=datetime.now() - timedelta(days=1),
                location="Northern Region",
            )
        ]


# Singleton instance
disaster_service = DisasterService()
