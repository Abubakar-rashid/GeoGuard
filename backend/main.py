"""
GeoGuard Backend - FastAPI Application
Main entry point for the API server
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api.v1 import disasters, ai_assistant, weather, survival_guides
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("GeoGuard API Starting...")
    yield
    # Shutdown
    print("GeoGuard API Shutting down...")


app = FastAPI(
    title="GeoGuard API",
    description="Backend API for GeoGuard disaster safety application",
    version="1.0.0",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(disasters.router, prefix="/api/v1/disasters", tags=["Disasters"])
app.include_router(ai_assistant.router, prefix="/api/v1/ai", tags=["AI Assistant"])
app.include_router(weather.router, prefix="/api/v1/weather", tags=["Weather"])
app.include_router(survival_guides.router, prefix="/api/v1/guides", tags=["Survival Guides"])


@app.get("/")
async def root():
    return {
        "message": "Welcome to GeoGuard API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
