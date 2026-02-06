# GeoGuard Backend API

FastAPI backend for the GeoGuard disaster safety application.

## Features

- **Disaster Data**: Fetches earthquake data from USGS, flood warnings, and weather alerts
- **AI Assistant**: Powered by Google Gemini for safety advice and chat
- **Weather Service**: Current weather and alerts from Open-Meteo and NWS
- **Survival Guides**: Pre-built survival guides for various disaster types

## Setup

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your API keys:

```bash
cp .env.example .env
```

Edit `.env`:
```
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 4. Run the Server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## API Documentation

Once the server is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Disasters
- `GET /api/v1/disasters/` - Get all disasters
- `GET /api/v1/disasters/earthquakes` - Get earthquakes
- `GET /api/v1/disasters/floods` - Get flood warnings
- `GET /api/v1/disasters/weather-alerts` - Get weather alerts
- `POST /api/v1/disasters/nearby` - Get disasters near a location

### AI Assistant
- `POST /api/v1/ai/chat` - Chat with AI assistant
- `POST /api/v1/ai/safety-advice` - Get safety advice
- `POST /api/v1/ai/precautions` - Get precautions
- `POST /api/v1/ai/seasonal-trends` - Analyze seasonal trends

### Weather
- `GET /api/v1/weather/` - Get current weather and alerts

### Survival Guides
- `GET /api/v1/guides/` - Get all survival guides
- `GET /api/v1/guides/{guide_id}` - Get a specific guide

## Project Structure

```
backend/
├── main.py                 # FastAPI application entry point
├── requirements.txt        # Python dependencies
├── .env.example           # Environment variables template
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── disasters.py
│   │       ├── ai_assistant.py
│   │       ├── weather.py
│   │       └── survival_guides.py
│   ├── core/
│   │   └── config.py      # Configuration settings
│   ├── models/
│   │   ├── disaster.py
│   │   ├── weather.py
│   │   ├── ai_assistant.py
│   │   └── survival_guide.py
│   └── services/
│       ├── disaster_service.py
│       ├── ai_assistant_service.py
│       ├── weather_service.py
│       └── survival_guide_service.py
```
