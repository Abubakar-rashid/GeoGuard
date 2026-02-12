"""
Disaster service for fetching disaster data from external APIs and local CSV
"""

import httpx
import pandas as pd
import os
from datetime import datetime, timedelta
from typing import List, Optional
from app.models.disaster import Disaster, DisasterType, SeverityLevel
from app.models.country_eda import CountryEDA, DisasterStats, RiskAssessment, CountrySeasonalRisk
from app.core.config import settings


class DisasterService:
    def __init__(self):
        self.usgs_base_url = settings.usgs_base_url
        self.gdacs_base_url = settings.gdacs_base_url
        # CSV file path for local disaster data
        self.csv_file_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "data", "cleaned-data.csv"
        )
        self._df = None

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

    def _load_csv_data(self) -> Optional[pd.DataFrame]:
        """Load CSV data from file (cached)"""
        if self._df is None:
            try:
                if os.path.exists(self.csv_file_path):
                    self._df = pd.read_csv(self.csv_file_path)
                else:
                    print(f"CSV file not found at {self.csv_file_path}")
                    return None
            except Exception as e:
                print(f"Error loading CSV file: {e}")
                return None
        return self._df

    async def search_countries(self, query: str) -> List[str]:
        """Search for countries by name from CSV data"""
        try:
            df = self._load_csv_data()
            if df is None or "Country" not in df.columns:
                return []
            
            # Get unique countries and filter by query
            countries = df["Country"].str.strip().unique()
            matching_countries = [
                country for country in countries
                if query.lower() in country.lower()
            ]
            
            # Sort alphabetically and return
            return sorted(list(set(matching_countries)))
        except Exception as e:
            print(f"Error searching countries: {e}")
            return []

    async def get_country_eda(self, country_name: str) -> Optional[CountryEDA]:
        """Get Exploratory Data Analysis (EDA) for a specific country from CSV data"""
        try:
            df = self._load_csv_data()
            if df is None or "Country" not in df.columns:
                return None
            
            # Filter data for the country
            country_df = df[df["Country"].str.strip() == country_name.strip()]
            if country_df.empty:
                return None
            
            # Get country code (ISO)
            country_code = country_df["ISO"].iloc[0] if "ISO" in country_df.columns else "XX"
            
            # Calculate coordinates (use first available)
            latitude = 0.0
            longitude = 0.0
            if "Latitude" in country_df.columns and "Longitude" in country_df.columns:
                valid_coords = country_df.dropna(subset=["Latitude", "Longitude"])
                if not valid_coords.empty:
                    latitude = float(valid_coords["Latitude"].iloc[0])
                    longitude = float(valid_coords["Longitude"].iloc[0])
            
            # Count disasters by type
            earthquake_count = len(country_df[country_df["Disaster Type"].str.contains("Earthquake|earthquake", na=False, case=False)])
            flood_count = len(country_df[country_df["Disaster Type"].str.contains("Flood|flood", na=False, case=False)])
            weather_count = len(country_df[country_df["Disaster Type"].str.contains("Storm|storm|Wind|wind|Heat|heat", na=False, case=False)])
            
            # Calculate magnitude stats
            def get_magnitude_stats(type_filter_col, type_keywords):
                type_df = country_df[country_df[type_filter_col].str.contains(type_keywords, na=False, case=False)]
                if "Magnitude" in type_df.columns:
                    mags = pd.to_numeric(type_df["Magnitude"], errors="coerce").dropna()
                    if len(mags) > 0:
                        return float(mags.mean()), float(mags.max())
                return 0.0, 0.0
            
            earthquake_avg_mag, earthquake_max_mag = get_magnitude_stats("Disaster Type", "Earthquake|earthquake")
            flood_avg_mag, flood_max_mag = get_magnitude_stats("Disaster Type", "Flood|flood")
            weather_avg_mag, weather_max_mag = get_magnitude_stats("Disaster Type", "Storm|storm|Wind|wind|Heat|heat")
            
            # Create disaster statistics
            earthquake_stats = DisasterStats(
                type="earthquake",
                total_count=earthquake_count,
                average_magnitude=earthquake_avg_mag,
                max_magnitude=earthquake_max_mag,
                high_risk_count=len(country_df[country_df["Disaster Type"].str.contains("Earthquake|earthquake", na=False, case=False)] if "Total Deaths" in country_df.columns else False),
                medium_risk_count=0,
                low_risk_count=0,
                recent_count=0,
            )
            
            flood_stats = DisasterStats(
                type="flood",
                total_count=flood_count,
                average_magnitude=flood_avg_mag,
                max_magnitude=flood_max_mag,
                high_risk_count=0,
                medium_risk_count=0,
                low_risk_count=0,
                recent_count=0,
            )
            
            weather_stats = DisasterStats(
                type="weather",
                total_count=weather_count,
                average_magnitude=weather_avg_mag,
                max_magnitude=weather_max_mag,
                high_risk_count=0,
                medium_risk_count=0,
                low_risk_count=0,
                recent_count=0,
            )
            
            # Calculate total disaster counts
            total_disasters = len(country_df)
            
            # Determine primary hazard
            disaster_types = {
                "Earthquake": earthquake_count,
                "Flood": flood_count,
                "Weather": weather_count,
            }
            primary_hazard = max(disaster_types, key=disaster_types.get)
            secondary_hazards = [k for k, v in disaster_types.items() if k != primary_hazard and v > 0]
            
            # Determine risk level
            if total_disasters > 50:
                risk_level = "critical"
                risk_score = 95.0
            elif total_disasters > 30:
                risk_level = "high"
                risk_score = 75.0
            elif total_disasters > 10:
                risk_level = "medium"
                risk_score = 50.0
            else:
                risk_level = "low"
                risk_score = 25.0
            
            # Risk assessment
            risk_assessment = RiskAssessment(
                overall_risk_level=risk_level,
                risk_score=risk_score,
                primary_hazard=primary_hazard,
                secondary_hazards=secondary_hazards,
                last_major_event=None,
                days_since_event=None,
            )
            
            # Seasonal risks (simplified)
            seasonal_risks = [
                CountrySeasonalRisk(
                    season="spring",
                    risk_level="medium",
                    primary_hazards=[primary_hazard],
                    incident_frequency=total_disasters // 4 if total_disasters > 0 else 0,
                ),
                CountrySeasonalRisk(
                    season="summer",
                    risk_level="high",
                    primary_hazards=[primary_hazard],
                    incident_frequency=total_disasters // 3 if total_disasters > 0 else 0,
                ),
                CountrySeasonalRisk(
                    season="fall",
                    risk_level="medium",
                    primary_hazards=[primary_hazard],
                    incident_frequency=total_disasters // 4 if total_disasters > 0 else 0,
                ),
                CountrySeasonalRisk(
                    season="winter",
                    risk_level="low",
                    primary_hazards=[primary_hazard],
                    incident_frequency=total_disasters // 4 if total_disasters > 0 else 0,
                ),
            ]
            
            # Safety recommendations
            safety_recommendations = [
                f"Stay aware of {primary_hazard.lower()} risks in {country_name}",
                "Follow local emergency alerts and warnings",
                "Prepare emergency kit with essentials",
                "Know evacuation routes in your area",
            ]
            
            return CountryEDA(
                country_name=country_name,
                country_code=str(country_code),
                latitude=latitude,
                longitude=longitude,
                area_sq_km=0.0,
                population=None,
                earthquake_stats=earthquake_stats,
                flood_stats=flood_stats,
                weather_stats=weather_stats,
                risk_assessment=risk_assessment,
                seasonal_risks=seasonal_risks,
                total_disasters_last_year=total_disasters,
                total_disasters_last_5_years=total_disasters,
                trend_direction="stable",
                trend_percentage=0.0,
                safety_recommendations=safety_recommendations,
                last_updated=datetime.now(),
            )
        except Exception as e:
            print(f"Error fetching country EDA: {e}")
            return None


# Singleton instance
disaster_service = DisasterService()
