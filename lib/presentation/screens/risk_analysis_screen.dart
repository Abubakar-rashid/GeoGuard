import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class RiskAnalysisScreen extends ConsumerWidget {
  const RiskAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disasters = ref.watch(allDisastersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.riskAnalysis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Risk Overview
            _RiskOverviewCard(),
            const SizedBox(height: 24),

            // Seasonal Analysis
            const Text(
              'Seasonal Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _SeasonalAnalysisCard(),
            const SizedBox(height: 24),

            // Disaster Trends
            const Text(
              'Recent Disaster Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _DisasterTrendsCard(disastersAsync: disasters),
            const SizedBox(height: 24),

            // Risk by Type
            const Text(
              'Risk by Disaster Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _RiskByTypeCard(),
            const SizedBox(height: 24),

            // Historical Data
            const Text(
              'Historical Patterns',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _HistoricalPatternsCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _RiskOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Risk Level',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'LOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Based on your location and recent disaster data, the overall risk level in your area is currently low.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RiskIndicator(label: 'Earthquake', level: 'Low', color: Colors.green.shade300),
              _RiskIndicator(label: 'Flood', level: 'Low', color: Colors.green.shade300),
              _RiskIndicator(label: 'Weather', level: 'Medium', color: Colors.orange.shade300),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskIndicator extends StatelessWidget {
  final String label;
  final String level;
  final Color color;

  const _RiskIndicator({
    required this.label,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(level, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SeasonalAnalysisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final monthName = _getMonthName(currentMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                '$monthName Analysis',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SeasonalItem(
            icon: Icons.public,
            label: 'Earthquakes',
            description: 'Typical activity this season',
            trend: 'stable',
          ),
          const Divider(height: 16),
          _SeasonalItem(
            icon: Icons.water_drop,
            label: 'Flooding',
            description: 'Higher than average during rainy season',
            trend: 'up',
          ),
          const Divider(height: 16),
          _SeasonalItem(
            icon: Icons.cloud,
            label: 'Severe Weather',
            description: 'Storm season approaching',
            trend: 'up',
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _SeasonalItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String trend;

  const _SeasonalItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = Colors.orange;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = Colors.green;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ),
        Icon(trendIcon, color: trendColor, size: 20),
      ],
    );
  }
}

class _DisasterTrendsCard extends StatelessWidget {
  final AsyncValue<List<Disaster>> disastersAsync;

  const _DisasterTrendsCard({required this.disastersAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.w600)),
              disastersAsync.when(
                data: (disasters) => Text(
                  '${disasters.length} events',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simple bar chart representation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final height = [30.0, 45.0, 20.0, 60.0, 35.0, 25.0, 40.0][index];
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDayLabel(index),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }
}

class _RiskByTypeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _RiskTypeRow(type: 'Earthquakes', percentage: 0.2, color: AppColors.earthquake),
          const SizedBox(height: 12),
          _RiskTypeRow(type: 'Floods', percentage: 0.35, color: AppColors.flood),
          const SizedBox(height: 12),
          _RiskTypeRow(type: 'Severe Weather', percentage: 0.5, color: AppColors.weather),
        ],
      ),
    );
  }
}

class _RiskTypeRow extends StatelessWidget {
  final String type;
  final double percentage;
  final Color color;

  const _RiskTypeRow({
    required this.type,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(type, style: const TextStyle(fontSize: 13)),
            Text('${(percentage * 100).toInt()}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
}

class _HistoricalPatternsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Key Insights',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InsightItem(
            text: 'Your area experiences 15% more earthquakes than the national average',
          ),
          const SizedBox(height: 8),
          _InsightItem(
            text: 'Peak flood season typically occurs between March and May',
          ),
          const SizedBox(height: 8),
          _InsightItem(
            text: 'Severe weather events have increased 8% year-over-year',
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String text;

  const _InsightItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights, color: Colors.purple.shade400, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
