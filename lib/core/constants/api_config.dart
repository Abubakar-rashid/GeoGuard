/// API configuration for GeoGuard backend
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API
  /// Change this to your production URL when deploying
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator / Web
  // static const String baseUrl = 'https://your-production-url.com'; // Production

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Endpoints
  static String get disasters => '$apiBaseUrl/disasters';
  static String get earthquakes => '$apiBaseUrl/disasters/earthquakes';
  static String get floods => '$apiBaseUrl/disasters/floods';
  static String get weatherAlerts => '$apiBaseUrl/disasters/weather-alerts';
  static String get nearbyDisasters => '$apiBaseUrl/disasters/nearby';
  static String get searchCountries => '$apiBaseUrl/disasters/countries/search';
  static String get checkRisk => '$apiBaseUrl/disasters/check-risk';
  static String countryEDA(String countryName) => '$apiBaseUrl/disasters/country/$countryName/eda';


  static String get aiChat => '$apiBaseUrl/ai/chat';
  static String get aiSafetyAdvice => '$apiBaseUrl/ai/safety-advice';
  static String get aiPrecautions => '$apiBaseUrl/ai/precautions';
  static String get aiSeasonalTrends => '$apiBaseUrl/ai/seasonal-trends';

  static String get weather => '$apiBaseUrl/weather';

  static String get survivalGuides => '$apiBaseUrl/guides';
  static String survivalGuide(String id) => '$apiBaseUrl/guides/$id';
}
