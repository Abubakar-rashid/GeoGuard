"""
Configuration settings for the GeoGuard API
"""

import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # API Keys
    huggingface_api_token: str = ""
    google_maps_api_key: str = ""
    gemini_api_key: str = ""
    groq_api_key: str = ""
    tomorrow_api_key: str = ""

    # AI models
    # Hugging Face model ID (for HF path)
    huggingface_model_id: str = "Qwen/Qwen3.5-9B"
    # Gemini model ID (for Gemini path). Example: text-bison-001
    gemini_model_id: str = "text-bison-001"
    groq_model: str = "llama-3.1-8b-instant"

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
