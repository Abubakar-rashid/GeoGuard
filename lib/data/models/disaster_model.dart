import 'package:equatable/equatable.dart';

enum DisasterType { earthquake, flood, weather }

enum SeverityLevel { low, medium, high }

class Disaster extends Equatable {
  final String id;
  final DisasterType type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double magnitude; // For earthquakes, or intensity for other types
  final SeverityLevel severity;
  final double radiusKm; // Affected radius in kilometers
  final DateTime timestamp;
  final String? location;
  final double? distanceFromUser; // Calculated based on user's location

  const Disaster({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.magnitude,
    required this.severity,
    required this.radiusKm,
    required this.timestamp,
    this.location,
    this.distanceFromUser,
  });

  Disaster copyWith({
    String? id,
    DisasterType? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    double? magnitude,
    SeverityLevel? severity,
    double? radiusKm,
    DateTime? timestamp,
    String? location,
    double? distanceFromUser,
  }) {
    return Disaster(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      magnitude: magnitude ?? this.magnitude,
      severity: severity ?? this.severity,
      radiusKm: radiusKm ?? this.radiusKm,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }

  /// Parse JSON from backend API
  factory Disaster.fromJson(Map<String, dynamic> json) {
    return Disaster(
      id: json['id'] as String,
      type: _parseDisasterType(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      magnitude: (json['magnitude'] as num).toDouble(),
      severity: _parseSeverityLevel(json['severity'] as String),
      radiusKm: (json['radius_km'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as String?,
      distanceFromUser: json['distance_from_user'] != null
          ? (json['distance_from_user'] as num).toDouble()
          : null,
    );
  }

  static DisasterType _parseDisasterType(String type) {
    switch (type) {
      case 'earthquake':
        return DisasterType.earthquake;
      case 'flood':
        return DisasterType.flood;
      case 'weather':
        return DisasterType.weather;
      default:
        return DisasterType.earthquake;
    }
  }

  static SeverityLevel _parseSeverityLevel(String severity) {
    switch (severity) {
      case 'low':
        return SeverityLevel.low;
      case 'medium':
        return SeverityLevel.medium;
      case 'high':
        return SeverityLevel.high;
      default:
        return SeverityLevel.low;
    }
  }

  factory Disaster.fromUsgsJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    final mag = (properties['mag'] as num?)?.toDouble() ?? 0.0;

    SeverityLevel severity;
    if (mag >= 6.0) {
      severity = SeverityLevel.high;
    } else if (mag >= 4.0) {
      severity = SeverityLevel.medium;
    } else {
      severity = SeverityLevel.low;
    }

    // Calculate radius based on magnitude (simplified formula)
    final radiusKm = mag * 20;

    return Disaster(
      id: json['id'] as String,
      type: DisasterType.earthquake,
      title: properties['title'] as String? ?? 'Earthquake',
      description: properties['place'] as String? ?? 'Unknown location',
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      magnitude: mag,
      severity: severity,
      radiusKm: radiusKm,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        properties['time'] as int,
      ),
      location: properties['place'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'magnitude': magnitude,
      'severity': severity.name,
      'radiusKm': radiusKm,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'distanceFromUser': distanceFromUser,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        latitude,
        longitude,
        magnitude,
        severity,
        radiusKm,
        timestamp,
        location,
        distanceFromUser,
      ];
}
