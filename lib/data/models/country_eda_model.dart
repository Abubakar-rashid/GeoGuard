import 'package:equatable/equatable.dart';

/// Statistics for a specific disaster type in a country
class DisasterStats extends Equatable {
  final String type; // "earthquake", "flood", "weather"
  final int totalCount;
  final double averageMagnitude;
  final double maxMagnitude;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int recentCount; // Events in last 30 days

  const DisasterStats({
    required this.type,
    required this.totalCount,
    required this.averageMagnitude,
    required this.maxMagnitude,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.recentCount,
  });

  factory DisasterStats.fromJson(Map<String, dynamic> json) {
    return DisasterStats(
      type: json['type'] as String,
      totalCount: json['total_count'] as int,
      averageMagnitude: (json['average_magnitude'] as num).toDouble(),
      maxMagnitude: (json['max_magnitude'] as num).toDouble(),
      highRiskCount: json['high_risk_count'] as int,
      mediumRiskCount: json['medium_risk_count'] as int,
      lowRiskCount: json['low_risk_count'] as int,
      recentCount: json['recent_count'] as int,
    );
  }

  @override
  List<Object?> get props => [
    type, totalCount, averageMagnitude, maxMagnitude,
    highRiskCount, mediumRiskCount, lowRiskCount, recentCount
  ];
}

/// Overall risk assessment for a country
class RiskAssessment extends Equatable {
  final String overallRiskLevel; // "low", "medium", "high", "critical"
  final double riskScore; // 0-100
  final String primaryHazard; // Most common/dangerous disaster type
  final List<String> secondaryHazards;
  final DateTime? lastMajorEvent;
  final int? daysSinceEvent;

  const RiskAssessment({
    required this.overallRiskLevel,
    required this.riskScore,
    required this.primaryHazard,
    required this.secondaryHazards,
    this.lastMajorEvent,
    this.daysSinceEvent,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      overallRiskLevel: json['overall_risk_level'] as String,
      riskScore: (json['risk_score'] as num).toDouble(),
      primaryHazard: json['primary_hazard'] as String,
      secondaryHazards: List<String>.from(json['secondary_hazards'] as List),
      lastMajorEvent: json['last_major_event'] != null
          ? DateTime.parse(json['last_major_event'] as String)
          : null,
      daysSinceEvent: json['days_since_event'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    overallRiskLevel, riskScore, primaryHazard, secondaryHazards,
    lastMajorEvent, daysSinceEvent
  ];
}

/// Seasonal risk patterns for a country
class CountrySeasonalRisk extends Equatable {
  final String season; // "spring", "summer", "fall", "winter"
  final String riskLevel; // "low", "medium", "high"
  final List<String> primaryHazards;
  final int incidentFrequency; // Average incidents per month

  const CountrySeasonalRisk({
    required this.season,
    required this.riskLevel,
    required this.primaryHazards,
    required this.incidentFrequency,
  });

  factory CountrySeasonalRisk.fromJson(Map<String, dynamic> json) {
    return CountrySeasonalRisk(
      season: json['season'] as String,
      riskLevel: json['risk_level'] as String,
      primaryHazards: List<String>.from(json['primary_hazards'] as List),
      incidentFrequency: json['incident_frequency'] as int,
    );
  }

  @override
  List<Object?> get props => [season, riskLevel, primaryHazards, incidentFrequency];
}

/// Complete EDA overview for a country
class CountryEDA extends Equatable {
  final String countryName;
  final String countryCode; // ISO 3166-1 alpha-2 code
  final double latitude;
  final double longitude;
  final double areaSqKm;
  final int? population;
  
  // Disaster Statistics
  final DisasterStats earthquakeStats;
  final DisasterStats floodStats;
  final DisasterStats weatherStats;
  
  // Risk Assessment
  final RiskAssessment riskAssessment;
  
  // Seasonal Patterns
  final List<CountrySeasonalRisk> seasonalRisks;
  
  // Historical Data
  final int totalDisastersLastYear;
  final int totalDisastersLast5Years;
  
  // Trends
  final String trendDirection; // "increasing", "stable", "decreasing"
  final double trendPercentage; // Year-over-year change percentage
  
  // Recommendations
  final List<String> safetyRecommendations;
  
  // Last Updated
  final DateTime lastUpdated;

  const CountryEDA({
    required this.countryName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.areaSqKm,
    this.population,
    required this.earthquakeStats,
    required this.floodStats,
    required this.weatherStats,
    required this.riskAssessment,
    required this.seasonalRisks,
    required this.totalDisastersLastYear,
    required this.totalDisastersLast5Years,
    required this.trendDirection,
    required this.trendPercentage,
    required this.safetyRecommendations,
    required this.lastUpdated,
  });

  factory CountryEDA.fromJson(Map<String, dynamic> json) {
    return CountryEDA(
      countryName: json['country_name'] as String,
      countryCode: json['country_code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      areaSqKm: (json['area_sq_km'] as num).toDouble(),
      population: json['population'] as int?,
      earthquakeStats: DisasterStats.fromJson(json['earthquake_stats'] as Map<String, dynamic>),
      floodStats: DisasterStats.fromJson(json['flood_stats'] as Map<String, dynamic>),
      weatherStats: DisasterStats.fromJson(json['weather_stats'] as Map<String, dynamic>),
      riskAssessment: RiskAssessment.fromJson(json['risk_assessment'] as Map<String, dynamic>),
      seasonalRisks: (json['seasonal_risks'] as List)
          .map((r) => CountrySeasonalRisk.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalDisastersLastYear: json['total_disasters_last_year'] as int,
      totalDisastersLast5Years: json['total_disasters_last_5_years'] as int,
      trendDirection: json['trend_direction'] as String,
      trendPercentage: (json['trend_percentage'] as num).toDouble(),
      safetyRecommendations: List<String>.from(json['safety_recommendations'] as List),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  @override
  List<Object?> get props => [
    countryName, countryCode, latitude, longitude, areaSqKm, population,
    earthquakeStats, floodStats, weatherStats, riskAssessment,
    seasonalRisks, totalDisastersLastYear, totalDisastersLast5Years,
    trendDirection, trendPercentage, safetyRecommendations, lastUpdated
  ];
}
