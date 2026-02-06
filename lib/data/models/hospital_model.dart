import 'package:equatable/equatable.dart';

class Hospital extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int? estimatedDriveMinutes;
  final String? address;
  final String? phoneNumber;

  const Hospital({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.estimatedDriveMinutes,
    this.address,
    this.phoneNumber,
  });

  Hospital copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? estimatedDriveMinutes,
    String? address,
    String? phoneNumber,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDriveMinutes: estimatedDriveMinutes ?? this.estimatedDriveMinutes,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'estimatedDriveMinutes': estimatedDriveMinutes,
      'address': address,
      'phoneNumber': phoneNumber,
    };
  }

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      distanceKm: json['distanceKm'] as double,
      estimatedDriveMinutes: json['estimatedDriveMinutes'] as int?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  String get distanceDisplay => '${distanceKm.toStringAsFixed(1)} km';

  String get driveTimeDisplay {
    if (estimatedDriveMinutes == null) return '';
    return '$estimatedDriveMinutes min drive';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        distanceKm,
        estimatedDriveMinutes,
        address,
        phoneNumber,
      ];
}
