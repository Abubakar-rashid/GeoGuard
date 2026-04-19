import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class RiskAnalysisScreen extends ConsumerWidget {
  const RiskAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disastersAsync = ref.watch(allDisastersProvider);
    final insightAsync = ref.watch(riskAnalyticsInsightProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.riskAnalysis),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: disastersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AnalyticsErrorState(error: error.toString()),
        data: (disasters) {
          final snapshot = _RiskAnalyticsSnapshot.fromDisasters(disasters);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allDisastersProvider);
              ref.invalidate(riskAnalyticsInsightProvider);
              await ref.read(allDisastersProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnalyticsHeroCard(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Live analytics',
                    subtitle:
                        'Current hazard activity pulled from your active alert feed.',
                  ),
                  const SizedBox(height: 12),
                  _MetricGrid(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Weekly trend',
                    subtitle:
                        'Bar chart of events detected across the last seven days.',
                  ),
                  const SizedBox(height: 12),
                  _WeeklyTrendChart(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Risk mix',
                    subtitle:
                        'How the current alert load is split by disaster type.',
                  ),
                  const SizedBox(height: 12),
                  _HazardMixCard(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Severity breakdown',
                    subtitle:
                        'A quick view of how much of the feed is low, medium, or high severity.',
                  ),
                  const SizedBox(height: 12),
                  _SeverityBreakdownCard(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'AI analysis',
                    subtitle:
                        'A short natural-language readout of what the current pattern means.',
                  ),
                  const SizedBox(height: 12),
                  _AiInsightCard(
                    snapshot: snapshot,
                    insightAsync: insightAsync,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Pattern notes',
                    subtitle:
                        'Useful takeaways from the current dataset without any AI call.',
                  ),
                  const SizedBox(height: 12),
                  _PatternNotesCard(snapshot: snapshot),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RiskAnalyticsSnapshot {
  final List<Disaster> disasters;
  final int totalEvents;
  final int earthquakeCount;
  final int floodCount;
  final int weatherCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final double averageMagnitude;
  final double maxMagnitude;
  final List<_DailyBucket> weeklyBuckets;
  final String trendLabel;
  final double trendPercent;
  final String dominantHazard;
  final double dominantHazardShare;
  final String peakDayLabel;
  final int peakDayCount;
  final String riskLabel;
  final Color riskColor;

  const _RiskAnalyticsSnapshot({
    required this.disasters,
    required this.totalEvents,
    required this.earthquakeCount,
    required this.floodCount,
    required this.weatherCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.averageMagnitude,
    required this.maxMagnitude,
    required this.weeklyBuckets,
    required this.trendLabel,
    required this.trendPercent,
    required this.dominantHazard,
    required this.dominantHazardShare,
    required this.peakDayLabel,
    required this.peakDayCount,
    required this.riskLabel,
    required this.riskColor,
  });

  factory _RiskAnalyticsSnapshot.fromDisasters(List<Disaster> disasters) {
    final sorted = [...disasters]
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    final now = DateTime.now();

    final weeklyBuckets = List.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final count = sorted.where((disaster) {
        final timestamp = disaster.timestamp;
        return timestamp.year == day.year &&
            timestamp.month == day.month &&
            timestamp.day == day.day;
      }).length;

      return _DailyBucket(
        label: _weekdayLabel(day.weekday),
        date: day,
        count: count,
      );
    });

    final earthquakeCount = sorted
        .where((disaster) => disaster.type == DisasterType.earthquake)
        .length;
    final floodCount = sorted
        .where((disaster) => disaster.type == DisasterType.flood)
        .length;
    final weatherCount = sorted
        .where((disaster) => disaster.type == DisasterType.weather)
        .length;
    final highCount = sorted
        .where((disaster) => disaster.severity == SeverityLevel.high)
        .length;
    final mediumCount = sorted
        .where((disaster) => disaster.severity == SeverityLevel.medium)
        .length;
    final lowCount = sorted
        .where((disaster) => disaster.severity == SeverityLevel.low)
        .length;
    final totalEvents = sorted.length;
    final double averageMagnitude = totalEvents == 0
        ? 0.0
        : sorted
                  .map((disaster) => disaster.magnitude)
                  .reduce((left, right) => left + right) /
              totalEvents;
    final double maxMagnitude = totalEvents == 0
        ? 0.0
        : sorted.map((disaster) => disaster.magnitude).reduce(math.max);

    final firstHalf = weeklyBuckets
        .take(3)
        .fold<int>(0, (sum, bucket) => sum + bucket.count);
    final secondHalf = weeklyBuckets
        .skip(4)
        .fold<int>(0, (sum, bucket) => sum + bucket.count);
    final double trendPercent = firstHalf == 0
        ? (secondHalf == 0 ? 0.0 : 100.0)
        : ((secondHalf - firstHalf) / firstHalf.abs()).abs() * 100;
    final trendLabel = secondHalf > firstHalf
        ? 'Rising'
        : secondHalf < firstHalf
        ? 'Cooling'
        : 'Stable';

    final dominant = <String, int>{
      'Earthquake': earthquakeCount,
      'Flood': floodCount,
      'Weather': weatherCount,
    };
    final dominantEntry = dominant.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final double dominantHazardShare = totalEvents == 0
        ? 0.0
        : dominantEntry.value / totalEvents * 100;

    final peakBucket = weeklyBuckets.isEmpty
        ? _DailyBucket(label: '--', date: now, count: 0)
        : weeklyBuckets.reduce(
            (left, right) => left.count >= right.count ? left : right,
          );

    final severityScore = totalEvents == 0
        ? 0.0
        : ((highCount * 1.0) + (mediumCount * 0.6) + (lowCount * 0.2)) /
              totalEvents *
              100;

    final riskLabel = severityScore >= 65
        ? 'High'
        : severityScore >= 35
        ? 'Moderate'
        : 'Low';

    final riskColor = severityScore >= 65
        ? AppColors.danger
        : severityScore >= 35
        ? AppColors.warning
        : AppColors.safe;

    return _RiskAnalyticsSnapshot(
      disasters: sorted,
      totalEvents: totalEvents,
      earthquakeCount: earthquakeCount,
      floodCount: floodCount,
      weatherCount: weatherCount,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
      averageMagnitude: averageMagnitude,
      maxMagnitude: maxMagnitude,
      weeklyBuckets: weeklyBuckets,
      trendLabel: trendLabel,
      trendPercent: trendPercent,
      dominantHazard: dominantEntry.key,
      dominantHazardShare: dominantHazardShare,
      peakDayLabel: peakBucket.label,
      peakDayCount: peakBucket.count,
      riskLabel: riskLabel,
      riskColor: riskColor,
    );
  }
}

class _DailyBucket {
  final String label;
  final DateTime date;
  final int count;

  const _DailyBucket({
    required this.label,
    required this.date,
    required this.count,
  });
}

class _AnalyticsHeroCard extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _AnalyticsHeroCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analytics overview',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      snapshot.riskLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _TrendBadge(
                label: snapshot.trendLabel,
                percent: snapshot.trendPercent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            snapshot.totalEvents == 0
                ? 'No active disaster events are loaded yet.'
                : '${snapshot.totalEvents} active events are feeding the dashboard, with ${snapshot.dominantHazard.toLowerCase()} currently leading the pattern.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                label:
                    '${snapshot.dominantHazard} ${snapshot.dominantHazardShare.toStringAsFixed(0)}%',
              ),
              _HeroChip(label: 'Peak day ${snapshot.peakDayLabel}'),
              _HeroChip(
                label: 'Max mag ${snapshot.maxMagnitude.toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String label;
  final double percent;

  const _TrendBadge({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final isRising = label == 'Rising';
    final isCooling = label == 'Cooling';
    final color = isRising
        ? Colors.orange.shade200
        : isCooling
        ? Colors.lightGreen.shade200
        : Colors.white70;
    final icon = isRising
        ? Icons.trending_up_rounded
        : isCooling
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _MetricGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _MetricCard(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.danger,
          label: 'Total alerts',
          value: snapshot.totalEvents.toString(),
        ),
        _MetricCard(
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.warning,
          label: 'Trend',
          value: '${snapshot.trendPercent.toStringAsFixed(0)}%',
          helper: snapshot.trendLabel,
        ),
        _MetricCard(
          icon: Icons.bolt_rounded,
          iconColor: AppColors.info,
          label: 'Average magnitude',
          value: snapshot.averageMagnitude.toStringAsFixed(1),
        ),
        _MetricCard(
          icon: Icons.shield_rounded,
          iconColor: snapshot.riskColor,
          label: 'Risk level',
          value: snapshot.riskLabel,
          helper: snapshot.peakDayCount == 0
              ? 'No peaks yet'
              : '${snapshot.peakDayCount} event${snapshot.peakDayCount == 1 ? '' : 's'} on ${snapshot.peakDayLabel}',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? helper;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (helper != null) ...[
                const SizedBox(height: 4),
                Text(
                  helper!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _WeeklyTrendChart({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final maxCount = snapshot.weeklyBuckets.fold<int>(
      0,
      (maxValue, bucket) => math.max(maxValue, bucket.count),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Events per day',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: snapshot.weeklyBuckets.map((bucket) {
                final barHeight = maxCount == 0
                    ? 10.0
                    : 24 + (bucket.count / maxCount) * 140;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          bucket.count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: bucket.count == maxCount && bucket.count > 0
                                ? AppColors.primaryDark
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: bucket.count == maxCount && bucket.count > 0
                                ? AppColors.primaryDark
                                : AppColors.info.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bucket.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HazardMixCard extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _HazardMixCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _HazardMixRow(
            label: 'Earthquake',
            count: snapshot.earthquakeCount,
            total: snapshot.totalEvents,
            color: AppColors.earthquake,
          ),
          const SizedBox(height: 14),
          _HazardMixRow(
            label: 'Flood',
            count: snapshot.floodCount,
            total: snapshot.totalEvents,
            color: AppColors.flood,
          ),
          const SizedBox(height: 14),
          _HazardMixRow(
            label: 'Weather',
            count: snapshot.weatherCount,
            total: snapshot.totalEvents,
            color: AppColors.weather,
          ),
        ],
      ),
    );
  }
}

class _HazardMixRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _HazardMixRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count events',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SeverityBreakdownCard extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _SeverityBreakdownCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final slices = [
      _SeveritySlice(
        label: 'High',
        value: snapshot.highCount,
        color: AppColors.danger,
      ),
      _SeveritySlice(
        label: 'Medium',
        value: snapshot.mediumCount,
        color: AppColors.warning,
      ),
      _SeveritySlice(
        label: 'Low',
        value: snapshot.lowCount,
        color: AppColors.safe,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(painter: _DonutChartPainter(slices: slices)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...slices.map(
                      (slice) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SeverityLegendRow(
                          slice: slice,
                          total: snapshot.totalEvents,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeveritySlice {
  final String label;
  final int value;
  final Color color;

  const _SeveritySlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SeverityLegendRow extends StatelessWidget {
  final _SeveritySlice slice;
  final int total;

  const _SeverityLegendRow({required this.slice, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (slice.value / total * 100).round();

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            slice.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${slice.value} ($percent%)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_SeveritySlice> slices;

  _DonutChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final strokeWidth = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);

    if (total == 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.grey.shade200;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) {
        continue;
      }

      final sweepAngle = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = strokeWidth
        ..color = slice.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _AiInsightCard extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;
  final AsyncValue<String> insightAsync;

  const _AiInsightCard({required this.snapshot, required this.insightAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.aiAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.aiAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI analysis',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          insightAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 3),
            ),
            error: (error, _) => Text(
              'AI analysis is unavailable right now.\n$error',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            data: (insight) {
              final lines = insight
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();

              if (lines.isEmpty) {
                return Text(
                  insight,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.brightness_1,
                              size: 7,
                              color: AppColors.aiAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                line.replaceFirst(RegExp(r'^[•\-]\s*'), ''),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallTag(label: '${snapshot.dominantHazard}-led pattern'),
              _SmallTag(label: '${snapshot.highCount} high severity'),
              _SmallTag(
                label:
                    '${snapshot.weeklyBuckets.fold<int>(0, (sum, bucket) => sum + bucket.count)} weekly events',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;

  const _SmallTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PatternNotesCard extends StatelessWidget {
  final _RiskAnalyticsSnapshot snapshot;

  const _PatternNotesCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      if (snapshot.totalEvents == 0)
        'No events are loaded yet, so the dashboard will stay quiet until the API returns data.',
      if (snapshot.totalEvents > 0)
        '${snapshot.dominantHazard} is currently the most common hazard type, contributing ${snapshot.dominantHazardShare.toStringAsFixed(0)}% of the feed.',
      if (snapshot.trendLabel == 'Rising')
        'The last part of the week shows more activity than the earlier part, so this pattern deserves closer watch.',
      if (snapshot.trendLabel == 'Cooling')
        'Recent activity is dropping compared with earlier days, which usually points to a calmer short-term outlook.',
      'The strongest event in the current feed reached magnitude ${snapshot.maxMagnitude.toStringAsFixed(1)}.',
      'The busiest day so far is ${snapshot.peakDayLabel} with ${snapshot.peakDayCount} event${snapshot.peakDayCount == 1 ? '' : 's'}.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: notes
            .map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NoteRow(text: note),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String text;

  const _NoteRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: AppColors.aiAccent,
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  final String error;

  const _AnalyticsErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '--';
  }
}
