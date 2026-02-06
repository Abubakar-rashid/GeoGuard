import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';

class RecentAlertsList extends StatelessWidget {
  final List<Disaster> disasters;

  const RecentAlertsList({super.key, required this.disasters});

  @override
  Widget build(BuildContext context) {
    if (disasters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No recent alerts in your area',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: disasters.map((disaster) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _AlertCard(disaster: disaster),
      )).toList(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Disaster disaster;

  const _AlertCard({required this.disaster});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _DisasterIcon(type: disaster.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      disaster.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SeverityBadge(
                      severity: disaster.severity,
                      magnitude: disaster.magnitude,
                      type: disaster.type,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  disaster.location ?? disaster.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disaster.timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _SeverityIndicator(severity: disaster.severity),
        ],
      ),
    );
  }
}

class _DisasterIcon extends StatelessWidget {
  final DisasterType type;

  const _DisasterIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    List<Color> gradientColors;

    switch (type) {
      case DisasterType.earthquake:
        icon = Icons.public;
        gradientColors = [Colors.brown.shade400, Colors.green.shade600];
        break;
      case DisasterType.flood:
        icon = Icons.water_drop;
        gradientColors = [Colors.blue.shade400, Colors.blue.shade600];
        break;
      case DisasterType.weather:
        icon = Icons.cloud;
        gradientColors = [Colors.purple.shade400, Colors.orange.shade400];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final SeverityLevel severity;
  final double magnitude;
  final DisasterType type;

  const _SeverityBadge({
    required this.severity,
    required this.magnitude,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    switch (severity) {
      case SeverityLevel.high:
        bgColor = AppColors.severityHigh;
        break;
      case SeverityLevel.medium:
        bgColor = AppColors.severityMedium;
        break;
      case SeverityLevel.low:
        bgColor = AppColors.severityLow;
        break;
    }

    if (type == DisasterType.earthquake) {
      text = '${magnitude.toStringAsFixed(1)} M';
    } else {
      text = 'Level ${magnitude.toInt()}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  final SeverityLevel severity;

  const _SeverityIndicator({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (severity) {
      case SeverityLevel.high:
        color = AppColors.severityHigh;
        break;
      case SeverityLevel.medium:
        color = AppColors.severityMedium;
        break;
      case SeverityLevel.low:
        color = AppColors.severityLow;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class RecentAlertsLoading extends StatelessWidget {
  const RecentAlertsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }
}
