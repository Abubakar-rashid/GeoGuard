import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for GeoGuard backend
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API
  /// Automatically selects local emulator URL for Android and localhost for other targets.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    // iOS Simulator and desktop (macOS, linux, windows) use localhost
    return 'http://localhost:8000';
  }

  // For manual override (optional): set environment variable in your launch config
  // e.g. --dart-define=API_BASE_URL=http://192.168.1.10:8000
  static String get apiBaseUrl {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    return '$baseUrl$apiVersion';
  }

  /// API version prefix
  static const String apiVersion = '/api/v1';

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
