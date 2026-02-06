import '../models/disaster_model.dart';
import '../../core/constants/api_config.dart';
import 'api_client.dart';

/// Service for fetching disaster data from the backend API
class DisasterService {
  final ApiClient _apiClient;

  DisasterService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch earthquakes from backend API
  Future<List<Disaster>> getEarthquakes({
    double? latitude,
    double? longitude,
    double radiusKm = 500,
    double minMagnitude = 2.5,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'min_magnitude': minMagnitude,
        'limit': limit,
        'radius_km': radiusKm,
      };

      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _apiClient.get(
        ApiConfig.earthquakes,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((d) => Disaster.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching earthquakes: $e');
      return [];
    }
  }

  /// Fetch earthquakes near a specific location
  Future<List<Disaster>> getEarthquakesNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 500,
    double minMagnitude = 2.5,
  }) async {
    return getEarthquakes(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      minMagnitude: minMagnitude,
    );
  }

  /// Get flood warnings from backend API
  Future<List<Disaster>> getFloodWarnings({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _apiClient.get(
        ApiConfig.floods,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((d) => Disaster.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching flood warnings: $e');
      return [];
    }
  }

  /// Get weather alerts from backend API
  Future<List<Disaster>> getWeatherAlerts({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _apiClient.get(
        ApiConfig.weatherAlerts,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((d) => Disaster.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching weather alerts: $e');
      return [];
    }
  }

  /// Get all disasters combined from backend API
  Future<List<Disaster>> getAllDisasters({
    double? latitude,
    double? longitude,
    double radiusKm = 500,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'radius_km': radiusKm,
      };
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _apiClient.get(
        ApiConfig.disasters,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((d) => Disaster.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all disasters: $e');
      return [];
    }
  }
}
