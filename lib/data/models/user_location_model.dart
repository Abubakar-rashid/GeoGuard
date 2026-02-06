import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    required this.timestamp,
  });

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    DateTime? timestamp,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get displayAddress {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return address ?? 'Unknown location';
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        city,
        country,
        timestamp,
      ];
}
