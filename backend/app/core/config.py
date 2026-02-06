"""
Configuration settings for the GeoGuard API
"""

import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # API Keys
    gemini_api_key: str = ""
    google_maps_api_key: str = ""

    # External API URLs
    usgs_base_url: str = "https://earthquake.usgs.gov/fdsnws/event/1"
    open_meteo_base_url: str = "https://api.open-meteo.com/v1"
    gdacs_base_url: str = "https://www.gdacs.org/gdacsapi/api/events"
    nws_base_url: str = "https://api.weather.gov"
    nominatim_base_url: str = "https://nominatim.openstreetmap.org"
    google_places_base_url: str = "https://maps.googleapis.com/maps/api/place"

    # App settings
    debug: bool = True

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
