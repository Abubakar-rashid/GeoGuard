import 'package:equatable/equatable.dart';

/// A single day's weather risk data from the Tomorrow.io Forecast API.
class WeatherRiskDay extends Equatable {
  final String date;
  final double temperatureMax;
  final double temperatureMin;
  final double temperatureAvg;
  final double humidityAvg;
  final double rainMm;
  final double windSpeedAvg;
  final double windGustMax;
  final int uvIndexMax;
  final int precipProbability;
  final int weatherCode;
  final String risk; // "LOW" | "WINDY" | "HEAT" | "MODERATE" | "HIGH"

  const WeatherRiskDay({
    required this.date,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.temperatureAvg,
    required this.humidityAvg,
    required this.rainMm,
    required this.windSpeedAvg,
    required this.windGustMax,
    required this.uvIndexMax,
    required this.precipProbability,
    required this.weatherCode,
    required this.risk,
  });

  factory WeatherRiskDay.fromJson(Map<String, dynamic> json) {
    return WeatherRiskDay(
      date: json['date'] as String? ?? '',
      temperatureMax: (json['temperature_max'] as num?)?.toDouble() ?? 0.0,
      temperatureMin: (json['temperature_min'] as num?)?.toDouble() ?? 0.0,
      temperatureAvg: (json['temperature_avg'] as num?)?.toDouble() ?? 0.0,
      humidityAvg: (json['humidity_avg'] as num?)?.toDouble() ?? 0.0,
      rainMm: (json['rain_mm'] as num?)?.toDouble() ?? 0.0,
      windSpeedAvg: (json['wind_speed_avg'] as num?)?.toDouble() ?? 0.0,
      windGustMax: (json['wind_gust_max'] as num?)?.toDouble() ?? 0.0,
      uvIndexMax: (json['uv_index_max'] as num?)?.toInt() ?? 0,
      precipProbability: (json['precip_probability'] as num?)?.toInt() ?? 0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      risk: json['risk'] as String? ?? 'LOW',
    );
  }

  @override
  List<Object?> get props => [
        date,
        temperatureMax,
        temperatureMin,
        temperatureAvg,
        humidityAvg,
        rainMm,
        windSpeedAvg,
        windGustMax,
        uvIndexMax,
        precipProbability,
        weatherCode,
        risk,
      ];
}

/// Full response from the /check-weather-risk backend endpoint.
class WeatherRiskResponse extends Equatable {
  final double userLatitude;
  final double userLongitude;
  final String overallRisk; // "LOW" | "WINDY" | "HEAT" | "MODERATE" | "HIGH"
  final List<WeatherRiskDay> daily;
  final String? error;

  const WeatherRiskResponse({
    required this.userLatitude,
    required this.userLongitude,
    required this.overallRisk,
    required this.daily,
    this.error,
  });

  factory WeatherRiskResponse.fromJson(Map<String, dynamic> json) {
    final loc = json['user_location'] as Map<String, dynamic>?;
    final rawDaily = json['daily'] as List<dynamic>? ?? [];

    return WeatherRiskResponse(
      userLatitude: (loc?['latitude'] as num?)?.toDouble() ?? 0.0,
      userLongitude: (loc?['longitude'] as num?)?.toDouble() ?? 0.0,
      overallRisk: json['overall_risk'] as String? ?? 'UNKNOWN',
      daily: rawDaily
          .map((e) => WeatherRiskDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [userLatitude, userLongitude, overallRisk, daily, error];
}
