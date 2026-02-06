import 'package:equatable/equatable.dart';
import 'disaster_model.dart';

enum SafetyStatus { safe, warning, danger }

class SafetyState extends Equatable {
  final SafetyStatus status;
  final String message;
  final Disaster? nearestThreat;
  final double? distanceToNearestThreat;

  const SafetyState({
    required this.status,
    required this.message,
    this.nearestThreat,
    this.distanceToNearestThreat,
  });

  factory SafetyState.safe() {
    return const SafetyState(
      status: SafetyStatus.safe,
      message: 'No immediate threats detected',
    );
  }

  factory SafetyState.warning({
    required Disaster nearestThreat,
    required double distance,
  }) {
    return SafetyState(
      status: SafetyStatus.warning,
      message: 'Potential threat nearby',
      nearestThreat: nearestThreat,
      distanceToNearestThreat: distance,
    );
  }

  factory SafetyState.danger({
    required Disaster nearestThreat,
    required double distance,
  }) {
    return SafetyState(
      status: SafetyStatus.danger,
      message: 'Immediate threat detected!',
      nearestThreat: nearestThreat,
      distanceToNearestThreat: distance,
    );
  }

  String get statusText {
    switch (status) {
      case SafetyStatus.safe:
        return 'SAFE';
      case SafetyStatus.warning:
        return 'WARNING';
      case SafetyStatus.danger:
        return 'DANGER';
    }
  }

  String get riskLevel {
    switch (status) {
      case SafetyStatus.safe:
        return 'Low Risk';
      case SafetyStatus.warning:
        return 'Moderate Risk';
      case SafetyStatus.danger:
        return 'High Risk';
    }
  }

  String get distanceDisplay {
    if (distanceToNearestThreat == null) return '';
    return '${distanceToNearestThreat!.toStringAsFixed(0)} km away';
  }

  @override
  List<Object?> get props => [
        status,
        message,
        nearestThreat,
        distanceToNearestThreat,
      ];
}
