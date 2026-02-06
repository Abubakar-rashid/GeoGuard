# GeoGuard - Natural Disaster Safety App

A real-time safety application designed to keep users informed and safe during natural environmental hazards. Built with a **separated frontend/backend architecture**:
- **Frontend**: Flutter mobile app
- **Backend**: FastAPI (Python) REST API

## 🏗️ Architecture Overview

```
GeoGuard/
├── lib/                  # Flutter Frontend
│   ├── core/
│   │   └── constants/    # Colors, strings, theme, API config
│   ├── data/
│   │   ├── models/       # Data models
│   │   └── services/     # API client services
│   ├── presentation/
│   │   ├── screens/      # UI screens
│   │   ├── widgets/      # Reusable widgets
│   │   └── navigation/   # Navigation shell
│   └── providers/        # Riverpod state management
│
└── backend/              # FastAPI Backend
    ├── main.py           # FastAPI application
    ├── app/
    │   ├── api/v1/       # API endpoints
    │   ├── core/         # Configuration
    │   ├── models/       # Pydantic models
    │   └── services/     # Business logic & external API calls
    └── requirements.txt  # Python dependencies
```

## 📱 Features

### Home Screen
- **Safety Status Card** - Real-time SAFE/WARNING/DANGER status based on proximity to disasters
- **Quick Actions** - Quick access to Live Map, Emergency SOS, Survival Guide, and Risk Analysis
- **Recent Alerts** - List of recent disasters in your area with severity indicators
- **AI Safety Assistant** - LLM-powered chatbot for disaster safety advice

### Live Hazard Map
- Interactive map with threat circles showing affected areas
- Filter by disaster type (Earthquake, Flood, Weather)
- Severity legend (High, Medium, Low)
- User location tracking
- Nearest threat card with distance info

### Emergency SOS
- Press-and-hold SOS button to send alerts
- Emergency contacts management
- Quick dial to emergency services (911)
- Nearby hospitals with navigation
- Live location sharing

### Survival Guide
- Offline-available emergency guides
- Categories: Earthquake, Flood, Weather, First Aid
- Quick safety tips
- Downloadable content for offline use

### Risk Analysis
- Current risk level overview
- Seasonal disaster analysis
- Historical patterns and trends
- Risk by disaster type visualization

### Settings
- Push notifications toggle
- Alert sensitivity configuration
- Location tracking settings
- Dark mode support
- Emergency contacts management

## 🗺️ Maps API

This app uses **flutter_map** with **OpenStreetMap** tiles:
- **FREE** - No API key required
- **Open Source** - Based on OpenStreetMap data
- **Customizable** - Easy to add circles, markers, and overlays

Alternative options:
- **Google Maps** (`google_maps_flutter`) - Requires API key, more features
- **Mapbox** (`mapbox_gl`) - Requires API key, great customization

## 🌐 Data APIs Used

### Disaster Data (Free, No API Key Required)

1. **USGS Earthquake API**
   - URL: `https://earthquake.usgs.gov/fdsnws/event/1/query`
   - Real-time earthquake data worldwide
   - Supports location-based filtering

2. **Open-Meteo Weather API**
   - URL: `https://api.open-meteo.com/v1/forecast`
   - Weather forecasts and alerts
   - No API key required

3. **GDACS (Global Disaster Alert and Coordination System)**
   - URL: `https://www.gdacs.org/gdacsapi/api/events`
   - Floods, earthquakes, cyclones, droughts

4. **National Weather Service API (US)**
   - URL: `https://api.weather.gov/alerts/active`
   - Weather alerts for US locations

### AI Integration (Requires API Key)

**Google Gemini API** for AI Safety Assistant:
- Get API key from: https://makersuite.google.com/app/apikey
- Add to `lib/core/constants/api_endpoints.dart`

## 🏗️ Detailed Architecture

### Frontend (Flutter)
```
lib/
├── core/
│   └── constants/        # Colors, strings, theme, API config
├── data/
│   ├── models/           # Data models (Disaster, User, Hospital, etc.)
│   └── services/         # API client for backend communication
├── presentation/
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable widgets
│   └── navigation/       # Navigation shell with bottom nav
└── providers/            # Riverpod state management
```

### Backend (FastAPI)
```
backend/
├── main.py               # FastAPI application entry point
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
└── app/
    ├── api/v1/           # API route handlers
    │   ├── disasters.py
    │   ├── ai_assistant.py
    │   ├── weather.py
    │   └── survival_guides.py
    ├── core/
    │   └── config.py     # Settings and configuration
    ├── models/           # Pydantic data models
    │   ├── disaster.py
    │   ├── weather.py
    │   ├── ai_assistant.py
    │   └── survival_guide.py
    └── services/         # Business logic & external APIs
        ├── disaster_service.py
        ├── ai_assistant_service.py
        ├── weather_service.py
        └── survival_guide_service.py
```

### Design Patterns Used

1. **Clean Architecture** - Separation of concerns
2. **Repository Pattern** - Data layer abstraction
3. **Provider Pattern** - State management with Riverpod
4. **Dependency Injection** - Using Riverpod providers

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| flutter_map | Interactive maps |
| geolocator | Location services |
| dio | HTTP client |
| hive_flutter | Local storage |
| google_generative_ai | AI chatbot |
| url_launcher | Phone calls & navigation |

## 🚀 Getting Started

### Backend Setup (FastAPI)

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```

5. **Run the backend server**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
   
   API docs available at: `http://localhost:8000/docs`

### Frontend Setup (Flutter)

1. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API endpoint** (if needed)
   
   Edit `lib/core/constants/api_config.dart`:
   ```dart
   // For Android emulator
   static const String baseUrl = 'http://10.0.2.2:8000';
   
   // For iOS simulator / Web
   static const String baseUrl = 'http://localhost:8000';
   
   // For production
   static const String baseUrl = 'https://your-production-url.com';
   ```

3. **Enable Developer Mode on Windows** (required for symlinks)
   ```
   Settings > Privacy & Security > For developers > Developer Mode
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔌 API Endpoints

### Disasters
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/disasters/` | Get all disasters |
| GET | `/api/v1/disasters/earthquakes` | Get earthquakes |
| GET | `/api/v1/disasters/floods` | Get flood warnings |
| GET | `/api/v1/disasters/weather-alerts` | Get weather alerts |
| POST | `/api/v1/disasters/nearby` | Get disasters near location |

### AI Assistant
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ai/chat` | Chat with AI assistant |
| POST | `/api/v1/ai/safety-advice` | Get safety advice |
| POST | `/api/v1/ai/precautions` | Get precautions |
| POST | `/api/v1/ai/seasonal-trends` | Analyze seasonal trends |

### Weather
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/weather/` | Get current weather |

### Survival Guides
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/guides/` | Get all survival guides |
| GET | `/api/v1/guides/{id}` | Get specific guide |

## 📍 Platform Permissions

### Android
- Location (fine, coarse, background)
- Internet
- Phone calls
- SMS
- Notifications

### iOS
Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GeoGuard needs location to show nearby disasters</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>GeoGuard monitors your location for safety alerts</string>
```

## 🎨 Design

The app follows Material Design 3 with a safety-focused color scheme:
- **Green** - Safe status
- **Orange** - Warning status  
- **Red** - Danger/Emergency status
- **Blue** - Information and maps

## 📄 License

MIT License - Feel free to use and modify.
