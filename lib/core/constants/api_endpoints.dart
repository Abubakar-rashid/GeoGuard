class ApiEndpoints {
  ApiEndpoints._();

  // USGS Earthquake API (Free, no API key required)
  static const String usgsBaseUrl = 'https://earthquake.usgs.gov/fdsnws/event/1';
  static const String usgsEarthquakes = '$usgsBaseUrl/query';

  // Open-Meteo Weather API (Free, no API key required)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String weatherForecast = '$openMeteoBaseUrl/forecast';

  // Global Disaster Alert and Coordination System (GDACS) - For floods/disasters
  static const String gdacsBaseUrl = 'https://www.gdacs.org/gdacsapi/api/events';
  static const String gdacsEvents = '$gdacsBaseUrl/geteventlist';

  // National Weather Service API (US - Free, no API key)
  static const String nwsBaseUrl = 'https://api.weather.gov';
  static const String nwsAlerts = '$nwsBaseUrl/alerts/active';

  // OpenStreetMap Nominatim for reverse geocoding (Free)
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String reverseGeocode = '$nominatimBaseUrl/reverse';

  // Google Places API (requires API key - for nearby hospitals)
  static const String googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String nearbySearch = '$googlePlacesBaseUrl/nearbysearch/json';
}

class ApiKeys {
  ApiKeys._();

  // Add your API keys here
  // For production, use environment variables or secure storage
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
}
