import 'package:equatable/equatable.dart';

/// Model for earthquake risk data from the check-risk API
class EarthquakeRisk extends Equatable {
  final String id;
  final int? time;
  final double magnitude;
  final String place;
  final double latitude;
  final double longitude;
  final double depthKm;
  final double circleRadiusKm;
  final String severity;
  final double distanceFromUser;

  const EarthquakeRisk({
    required this.id,
    this.time,
    required this.magnitude,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.depthKm,
    required this.circleRadiusKm,
    required this.severity,
    required this.distanceFromUser,
  });

  factory EarthquakeRisk.fromJson(Map<String, dynamic> json) {
    return EarthquakeRisk(
      id: json['id'] as String? ?? '',
      time: json['time'] as int?,
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0.0,
      place: json['place'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      depthKm: (json['depth_km'] as num?)?.toDouble() ?? 0.0,
      circleRadiusKm: (json['circle_radius_km'] as num?)?.toDouble() ?? 10.0,
      severity: json['severity'] as String? ?? 'low',
      distanceFromUser: (json['distance_from_user'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DateTime? get dateTime {
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time!);
  }

  @override
  List<Object?> get props => [
        id,
        time,
        magnitude,
        place,
        latitude,
        longitude,
        depthKm,
        circleRadiusKm,
        severity,
        distanceFromUser,
      ];
}

/// Response model for the check-risk API
class EarthquakeRiskResponse extends Equatable {
  final double userLatitude;
  final double userLongitude;
  final double radiusKm;
  final double minMagnitude;
  final int daysChecked;
  final int earthquakeCount;
  final bool threatDetected;
  final String message;
  final List<EarthquakeRisk> earthquakes;

  const EarthquakeRiskResponse({
    required this.userLatitude,
    required this.userLongitude,
    required this.radiusKm,
    required this.minMagnitude,
    required this.daysChecked,
    required this.earthquakeCount,
    this.threatDetected = false,
    this.message = '',
    required this.earthquakes,
  });

  factory EarthquakeRiskResponse.fromJson(Map<String, dynamic> json) {
    final userLocation = json['user_location'] as Map<String, dynamic>?;
    final earthquakesList = json['earthquakes'] as List<dynamic>? ?? [];

    return EarthquakeRiskResponse(
      userLatitude: (userLocation?['latitude'] as num?)?.toDouble() ?? 0.0,
      userLongitude: (userLocation?['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 1000.0,
      minMagnitude: (json['min_magnitude'] as num?)?.toDouble() ?? 4.0,
      daysChecked: json['days_checked'] as int? ?? 7,
      earthquakeCount: json['earthquake_count'] as int? ?? 0,
      threatDetected: json['threat_detected'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      earthquakes: earthquakesList
          .map((e) => EarthquakeRisk.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        userLatitude,
        userLongitude,
        radiusKm,
        minMagnitude,
        daysChecked,
        earthquakeCount,
        threatDetected,
        message,
        earthquakes,
      ];
}
