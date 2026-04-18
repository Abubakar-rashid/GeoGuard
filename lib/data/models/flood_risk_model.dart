import 'package:equatable/equatable.dart';

/// A single day's flood risk data from the Open-Meteo Flood API.
class FloodRiskDay extends Equatable {
  final String date;
  final double? riverDischarge;
  final double? riverDischargeMean;
  final double? riverDischargeMax;
  final double? ratio;
  final String risk; // "LOW" | "MODERATE" | "HIGH" | "UNKNOWN"

  const FloodRiskDay({
    required this.date,
    this.riverDischarge,
    this.riverDischargeMean,
    this.riverDischargeMax,
    this.ratio,
    required this.risk,
  });

  factory FloodRiskDay.fromJson(Map<String, dynamic> json) {
    return FloodRiskDay(
      date: json['date'] as String? ?? '',
      riverDischarge: (json['river_discharge'] as num?)?.toDouble(),
      riverDischargeMean: (json['river_discharge_mean'] as num?)?.toDouble(),
      riverDischargeMax: (json['river_discharge_max'] as num?)?.toDouble(),
      ratio: (json['ratio'] as num?)?.toDouble(),
      risk: json['risk'] as String? ?? 'UNKNOWN',
    );
  }

  @override
  List<Object?> get props => [
        date,
        riverDischarge,
        riverDischargeMean,
        riverDischargeMax,
        ratio,
        risk,
      ];
}

/// Full response from the /check-flood-risk backend endpoint.
class FloodRiskResponse extends Equatable {
  final double userLatitude;
  final double userLongitude;
  final String overallRisk; // "LOW" | "MODERATE" | "HIGH" | "UNKNOWN"
  final int lowCount;
  final int moderateCount;
  final int highCount;
  final List<FloodRiskDay> daily;
  final String? error;

  const FloodRiskResponse({
    required this.userLatitude,
    required this.userLongitude,
    required this.overallRisk,
    required this.lowCount,
    required this.moderateCount,
    required this.highCount,
    required this.daily,
    this.error,
  });

  factory FloodRiskResponse.fromJson(Map<String, dynamic> json) {
    final loc = json['user_location'] as Map<String, dynamic>?;
    final counts = json['risk_counts'] as Map<String, dynamic>? ?? {};
    final rawDaily = json['daily'] as List<dynamic>? ?? [];

    return FloodRiskResponse(
      userLatitude: (loc?['latitude'] as num?)?.toDouble() ?? 0.0,
      userLongitude: (loc?['longitude'] as num?)?.toDouble() ?? 0.0,
      overallRisk: json['overall_risk'] as String? ?? 'UNKNOWN',
      lowCount: counts['LOW'] as int? ?? 0,
      moderateCount: counts['MODERATE'] as int? ?? 0,
      highCount: counts['HIGH'] as int? ?? 0,
      daily: rawDaily
          .map((e) => FloodRiskDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        userLatitude,
        userLongitude,
        overallRisk,
        lowCount,
        moderateCount,
        highCount,
        daily,
        error,
      ];
}
