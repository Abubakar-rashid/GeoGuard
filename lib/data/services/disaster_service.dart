import 'package:flutter/services.dart';
import '../models/disaster_model.dart';
import '../models/country_eda_model.dart';
import '../models/earthquake_risk_model.dart';
import '../models/flood_risk_model.dart';
import '../models/weather_risk_model.dart';
import '../../core/constants/api_config.dart';
import 'api_client.dart';

/// Service for fetching disaster data from local CSV file
class DisasterService {
  final ApiClient _apiClient;
  List<List<dynamic>>? _csvData;
  Map<String, dynamic>? _csvHeaders;

  DisasterService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Load and parse CSV data from assets
  Future<void> _loadCsvData() async {
    if (_csvData != null) return; // Already loaded

    try {
      print('[CSV] Starting to load CSV from assets...');
      final csvString = await rootBundle.loadString(
        'assets/data/cleaned-data.csv',
      );
      print('[CSV] Loaded CSV string, length: ${csvString.length}');

      // Parse CSV with quoted fields so columns stay aligned.
      _csvData = _parseCsvString(csvString);

      print('[CSV] Parsed CSV data, rows: ${_csvData!.length}');

      if (_csvData!.isEmpty) {
        print('[CSV] CSV file is empty');
        return;
      }

      // Store headers
      _csvHeaders = {};
      final headers = _csvData![0];
      print('[CSV] Headers: $headers');
      for (int i = 0; i < headers.length; i++) {
        _csvHeaders![headers[i].toString()] = i;
      }

      print('[CSV] CSV loaded successfully. Total rows: ${_csvData!.length}');
      print('[CSV] Column index for "Country": ${_getColumnIndex("Country")}');
    } catch (e) {
      print('[CSV] Error loading CSV: $e');
    }
  }

  /// Parse a CSV string into rows while preserving quoted commas and quotes.
  List<List<dynamic>> _parseCsvString(String csvString) {
    final rows = <List<dynamic>>[];
    final rowBuffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < csvString.length; i++) {
      final char = csvString[i];

      if (char == '"') {
        final nextIsQuote = i + 1 < csvString.length && csvString[i + 1] == '"';
        if (nextIsQuote) {
          rowBuffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if ((char == '\n' || char == '\r') && !inQuotes) {
        if (rowBuffer.isNotEmpty) {
          rows.add(_parseCSVLine(rowBuffer.toString()));
          rowBuffer.clear();
        }
        continue;
      }

      rowBuffer.write(char);
    }

    if (rowBuffer.isNotEmpty) {
      rows.add(_parseCSVLine(rowBuffer.toString()));
    }

    return rows;
  }

  /// Parse a single CSV line with support for quoted commas.
  List<dynamic> _parseCSVLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (nextIsQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  /// Get column index by name
  int? _getColumnIndex(String columnName) {
    return _csvHeaders?[columnName];
  }

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

  /// Check earthquake risk for a location
  /// Returns recent earthquakes near the user with magnitude >= minMagnitude within 1000 km
  Future<EarthquakeRiskResponse?> checkEarthquakeRisk({
    required double latitude,
    required double longitude,
    double radiusKm = 1000,
    double minMagnitude = 4.0,
    int days = 7,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'min_magnitude': minMagnitude,
        'days': days,
      };

      final response = await _apiClient.get(
        ApiConfig.checkRisk,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return EarthquakeRiskResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error checking earthquake risk: $e');
      return null;
    }
  }

  /// Check flood risk for a location using Open-Meteo Flood API.
  /// Returns daily river discharge data with LOW / MODERATE / HIGH risk ratings.
  Future<FloodRiskResponse?> checkFloodRisk({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await _apiClient.get(
        ApiConfig.checkFloodRisk,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return FloodRiskResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error checking flood risk: $e');
      return null;
    }
  }

  /// Check weather risk for a location using Tomorrow.io Forecast API.
  /// Returns daily weather data with LOW / WINDY / HEAT / MODERATE / HIGH risk ratings.
  Future<WeatherRiskResponse?> checkWeatherRisk({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await _apiClient.get(
        ApiConfig.checkWeatherRisk,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return WeatherRiskResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error checking weather risk: $e');
      return null;
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

  /// Get all disasters combined (currently returns empty - use country-specific data instead)
  Future<List<Disaster>> getAllDisasters({
    double? latitude,
    double? longitude,
    double radiusKm = 500,
  }) async {
    final results = await Future.wait([
      getEarthquakes(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
      getFloodWarnings(latitude: latitude, longitude: longitude),
      getWeatherAlerts(latitude: latitude, longitude: longitude),
    ]);

    final combined = <Disaster>[...results[0], ...results[1], ...results[2]];

    combined.sort((left, right) => right.timestamp.compareTo(left.timestamp));
    return combined;
  }

  /// Search for countries by name from CSV data
  Future<List<String>> searchCountries({required String query}) async {
    try {
      print('[SEARCH] Starting search for query: "$query"');
      await _loadCsvData();

      if (_csvData == null || _csvData!.isEmpty) {
        print('[SEARCH] Error: CSV data not loaded');
        return [];
      }

      print('[SEARCH] CSV data loaded. Total rows: ${_csvData!.length}');
      print('[SEARCH] Headers available: ${_csvHeaders?.keys.toList()}');

      final countryIndex = _getColumnIndex('Country');
      print('[SEARCH] Country column index: $countryIndex');

      if (countryIndex == null) {
        print('[SEARCH] Error: Country column not found in CSV');
        print('[SEARCH] Available columns: ${_csvHeaders?.keys.toString()}');
        return [];
      }

      // Get unique countries that match the query
      final countries = <String>{};
      print('[SEARCH] Searching through ${_csvData!.length - 1} data rows...');

      for (int i = 1; i < _csvData!.length; i++) {
        final row = _csvData![i];
        if (countryIndex < row.length) {
          final country = row[countryIndex].toString().trim();
          if (country.isNotEmpty &&
              country.toLowerCase().contains(query.toLowerCase())) {
            countries.add(country);
          }
        }
      }

      print(
        '[SEARCH] Found ${countries.length} matching countries: $countries',
      );
      return countries.toList()..sort();
    } catch (e) {
      print('[SEARCH] Error searching countries: $e');
      return [];
    }
  }

  /// Get EDA overview for a specific country from CSV data
  Future<CountryEDA?> getCountryEDA({required String countryName}) async {
    try {
      await _loadCsvData();

      if (_csvData == null || _csvData!.isEmpty) {
        print('Error: CSV data not loaded');
        return null;
      }

      // Filter rows for the selected country
      final countryIndex = _getColumnIndex('Country');
      if (countryIndex == null) {
        print('Error: Country column not found');
        return null;
      }

      final countryRows = <List<dynamic>>[];
      for (int i = 1; i < _csvData!.length; i++) {
        final row = _csvData![i];
        if (countryIndex < row.length &&
            row[countryIndex].toString().trim() == countryName.trim()) {
          countryRows.add(row);
        }
      }

      if (countryRows.isEmpty) {
        print('No data found for country: $countryName');
        return null;
      }

      // Extract data for EDA
      final isoIndex = _getColumnIndex('ISO');
      final latIndex = _getColumnIndex('Latitude');
      final lonIndex = _getColumnIndex('Longitude');
      final disasterTypeIndex = _getColumnIndex('Disaster Type');
      final magnitudeIndex = _getColumnIndex('Magnitude');
      final magnitudeScaleIndex = _getColumnIndex('Magnitude Scale');

      String countryCode = 'XX';
      double latitude = 0;
      double longitude = 0;

      if (isoIndex != null &&
          isoIndex < countryRows[0].length &&
          countryRows[0][isoIndex] != null) {
        countryCode = countryRows[0][isoIndex].toString();
      }

      if (latIndex != null &&
          latIndex < countryRows[0].length &&
          countryRows[0][latIndex] != null) {
        latitude = double.tryParse(countryRows[0][latIndex].toString()) ?? 0;
      }

      if (lonIndex != null &&
          lonIndex < countryRows[0].length &&
          countryRows[0][lonIndex] != null) {
        longitude = double.tryParse(countryRows[0][lonIndex].toString()) ?? 0;
      }

      // Count disasters by type
      int earthquakeCount = 0;
      int floodCount = 0;
      int weatherCount = 0;
      double earthquakeMag = 0;
      double floodMag = 0;
      double weatherMag = 0;

      for (final row in countryRows) {
        final disasterType =
            disasterTypeIndex != null && disasterTypeIndex < row.length
            ? row[disasterTypeIndex].toString().toLowerCase()
            : '';

        final magnitudeScale = magnitudeScaleIndex != null && magnitudeScaleIndex < row.length
            ? row[magnitudeScaleIndex].toString().toLowerCase()
            : '';

        final magnitude = magnitudeIndex != null && magnitudeIndex < row.length
            ? double.tryParse(row[magnitudeIndex].toString()) ?? 0
            : 0;

        if (disasterType.contains('earthquake')) {
          earthquakeCount++;
          // Only add magnitude if it's "Moment Magnitude" (valid earthquake scale)
          if (magnitudeScale.contains('moment') && magnitude > 0) {
            earthquakeMag += magnitude;
          }
        } else if (disasterType.contains('flood')) {
          floodCount++;
          // Floods don't have valid magnitude values (they have area in Km²)
          // So we skip adding magnitude for floods
        } else if (disasterType.contains('storm') ||
            disasterType.contains('wind') ||
            disasterType.contains('heat')) {
          weatherCount++;
          // Weather events also typically don't have magnitude in the expected format
          // So we skip adding magnitude for weather events
        }
      }

      final totalDisasters = countryRows.length;

      // Calculate averages
      final earthquakeAvg = earthquakeCount > 0
          ? earthquakeMag / earthquakeCount
          : 0;
      final floodAvg = floodCount > 0 ? floodMag / floodCount : 0;
      final weatherAvg = weatherCount > 0 ? weatherMag / weatherCount : 0;

      // Determine risk level
      String riskLevel;
      double riskScore;
      if (totalDisasters > 50) {
        riskLevel = 'critical';
        riskScore = 95.0;
      } else if (totalDisasters > 30) {
        riskLevel = 'high';
        riskScore = 75.0;
      } else if (totalDisasters > 10) {
        riskLevel = 'medium';
        riskScore = 50.0;
      } else {
        riskLevel = 'low';
        riskScore = 25.0;
      }

      // Create disaster stats
      final earthquakeStats = DisasterStats(
        type: 'earthquake',
        totalCount: earthquakeCount,
        averageMagnitude: earthquakeAvg.toDouble(),
        maxMagnitude: earthquakeCount > 0
            ? (earthquakeMag / earthquakeCount).toDouble()
            : 0,
        highRiskCount: earthquakeCount > 0
            ? (earthquakeCount * 0.3).toInt()
            : 0,
        mediumRiskCount: earthquakeCount > 0
            ? (earthquakeCount * 0.5).toInt()
            : 0,
        lowRiskCount: earthquakeCount > 0 ? (earthquakeCount * 0.2).toInt() : 0,
        recentCount: 0,
      );

      final floodStats = DisasterStats(
        type: 'flood',
        totalCount: floodCount,
        averageMagnitude: floodAvg.toDouble(),
        maxMagnitude: floodCount > 0 ? (floodMag / floodCount).toDouble() : 0,
        highRiskCount: floodCount > 0 ? (floodCount * 0.3).toInt() : 0,
        mediumRiskCount: floodCount > 0 ? (floodCount * 0.5).toInt() : 0,
        lowRiskCount: floodCount > 0 ? (floodCount * 0.2).toInt() : 0,
        recentCount: 0,
      );

      final weatherStats = DisasterStats(
        type: 'weather',
        totalCount: weatherCount,
        averageMagnitude: weatherAvg.toDouble(),
        maxMagnitude: weatherCount > 0
            ? (weatherMag / weatherCount).toDouble()
            : 0,
        highRiskCount: weatherCount > 0 ? (weatherCount * 0.3).toInt() : 0,
        mediumRiskCount: weatherCount > 0 ? (weatherCount * 0.5).toInt() : 0,
        lowRiskCount: weatherCount > 0 ? (weatherCount * 0.2).toInt() : 0,
        recentCount: 0,
      );

      // Determine primary hazard
      String primaryHazard = 'Earthquake';
      if (floodCount > earthquakeCount && floodCount > weatherCount) {
        primaryHazard = 'Flood';
      } else if (weatherCount > earthquakeCount && weatherCount > floodCount) {
        primaryHazard = 'Weather';
      }

      // Risk assessment
      final riskAssessment = RiskAssessment(
        overallRiskLevel: riskLevel,
        riskScore: riskScore,
        primaryHazard: primaryHazard,
        secondaryHazards: [],
        lastMajorEvent: null,
        daysSinceEvent: null,
      );

      // Seasonal risks
      final seasonalRisks = [
        CountrySeasonalRisk(
          season: 'spring',
          riskLevel: 'medium',
          primaryHazards: [primaryHazard],
          incidentFrequency: (totalDisasters / 4).toInt(),
        ),
        CountrySeasonalRisk(
          season: 'summer',
          riskLevel: 'high',
          primaryHazards: [primaryHazard],
          incidentFrequency: (totalDisasters / 3).toInt(),
        ),
        CountrySeasonalRisk(
          season: 'fall',
          riskLevel: 'medium',
          primaryHazards: [primaryHazard],
          incidentFrequency: (totalDisasters / 4).toInt(),
        ),
        CountrySeasonalRisk(
          season: 'winter',
          riskLevel: 'low',
          primaryHazards: [primaryHazard],
          incidentFrequency: (totalDisasters / 4).toInt(),
        ),
      ];

      // Safety recommendations
      final safetyRecommendations = [
        'Stay aware of $primaryHazard risks in $countryName',
        'Follow local emergency alerts and warnings',
        'Prepare emergency kit with essentials',
        'Know evacuation routes in your area',
      ];

      return CountryEDA(
        countryName: countryName,
        countryCode: countryCode,
        latitude: latitude,
        longitude: longitude,
        areaSqKm: 0.0,
        population: null,
        earthquakeStats: earthquakeStats,
        floodStats: floodStats,
        weatherStats: weatherStats,
        riskAssessment: riskAssessment,
        seasonalRisks: seasonalRisks,
        totalDisastersLastYear: totalDisasters,
        totalDisastersLast5Years: totalDisasters,
        trendDirection: 'stable',
        trendPercentage: 0.0,
        safetyRecommendations: safetyRecommendations,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching country EDA: $e');
      return null;
    }
  }
}
