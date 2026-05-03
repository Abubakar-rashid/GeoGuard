import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class CountryEdaScreen extends ConsumerStatefulWidget {
  final String? initialCountry;

  const CountryEdaScreen({super.key, this.initialCountry});

  @override
  ConsumerState<CountryEdaScreen> createState() => _CountryEdaScreenState();
}

class _CountryEdaScreenState extends ConsumerState<CountryEdaScreen> {
  late TextEditingController _searchController;
  List<String> _searchSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    if (widget.initialCountry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedCountryProvider.notifier).state = null;
      });
    }

    if (widget.initialCountry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectCountry(widget.initialCountry!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final suggestions = await ref.read(countrySearchProvider(query).future);
    setState(() {
      _searchSuggestions = suggestions;
      _isSearching = false;
    });
  }

  void _selectCountry(String country) {
    setState(() {
      _searchController.text = country;
      _searchSuggestions = [];
    });
    ref.read(selectedCountryProvider.notifier).state = country;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedCountryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.countryEdasearch),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            _buildSearchBox(),
            const SizedBox(height: 24),

            // Display EDA if country is selected
            if (selectedCountry != null)
              _buildCountryEDAView(selectedCountry)
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: AppStrings.searchCountry,
              prefix: const SizedBox(width: 12),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Suggestions List
        if (_searchSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchSuggestions.length,
              itemBuilder: (context, index) {
                final country = _searchSuggestions[index];
                return InkWell(
                  onTap: () => _selectCountry(country),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(country),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppStrings.searchingCountries,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCountryEDAView(String countryName) {
    final edaAsync = ref.watch(countryEdaProvider(countryName));

    return edaAsync.when(
      data: (eda) {
        if (eda == null) {
          return _buildErrorState();
        }
        return _buildEdaContent(eda);
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(),
    );
  }

  Widget _buildEdaContent(CountryEDA eda) {
    final snapshot = _CountryAnalyticsSnapshot.fromEda(eda);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountryAnalyticsHeroCard(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Country analytics',
          subtitle:
              'Charts and breakdowns for the country you selected from search.',
        ),
        const SizedBox(height: 12),
        _CountryMetricGrid(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Yearly comparison',
          subtitle:
              'How the selected country compares with its own 5-year average.',
        ),
        const SizedBox(height: 12),
        _CountryYearlyComparisonCard(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Hazard mix',
          subtitle: 'Which disaster types contribute most in this country.',
        ),
        const SizedBox(height: 12),
        _CountryHazardMixCard(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Severity breakdown',
          subtitle:
              'Donut chart showing the country’s high, medium, and low risk load.',
        ),
        const SizedBox(height: 12),
        _CountrySeverityDonutCard(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Seasonal pattern',
          subtitle:
              'Season-by-season incident frequency and risk level for the selected country.',
        ),
        const SizedBox(height: 12),
        _CountrySeasonalRiskChart(snapshot: snapshot),
        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Country insight',
          subtitle:
              'A short summary of what the selected country’s data means.',
        ),
        const SizedBox(height: 12),
        _CountryInsightCard(snapshot: snapshot),
        const SizedBox(height: 24),

        // Country Header
        _CountryHeaderCard(eda: eda),
        const SizedBox(height: 24),

        // Risk Assessment
        const Text(
          AppStrings.riskAssessment,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _RiskAssessmentCard(risk: eda.riskAssessment),
        const SizedBox(height: 24),

        // Disaster Statistics
        const Text(
          AppStrings.disasterStatistics,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _DisasterStatsCard(
          title: AppStrings.earthquakeStatistics,
          stats: eda.earthquakeStats,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _DisasterStatsCard(
          title: AppStrings.floodStatistics,
          stats: eda.floodStats,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _DisasterStatsCard(
          title: AppStrings.weatherStatistics,
          stats: eda.weatherStats,
          color: AppColors.aiAccent,
        ),
        const SizedBox(height: 24),

        // Historical Data
        const Text(
          AppStrings.historicalData,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _HistoricalDataCard(eda: eda),
        const SizedBox(height: 24),

        // Seasonal Risks
        const Text(
          AppStrings.seasonalRisks,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(eda.seasonalRisks.length, (index) {
          final seasonal = eda.seasonalRisks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SeasonalRiskCard(seasonal: seasonal),
          );
        }),
        const SizedBox(height: 24),

        // Safety Recommendations
        const Text(
          AppStrings.safetyRecommendations,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(eda.safetyRecommendations.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendationCard(
              recommendation: eda.safetyRecommendations[index],
              index: index + 1,
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppStrings.noCountrySelected,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a country to view its disaster risk overview',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              AppStrings.loadingCountryData,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              AppStrings.failedToLoadData,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                });
                ref.read(selectedCountryProvider.notifier).state = null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryAnalyticsSnapshot {
  final CountryEDA eda;
  final int totalEvents;
  final int earthquakeCount;
  final int floodCount;
  final int weatherCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final double maxMagnitude;
  final String trendLabel;
  final double trendPercent;
  final String dominantHazard;
  final double dominantHazardShare;
  final String riskLabel;
  final Color riskColor;
  final double fiveYearAverage;
  final List<_CountrySeasonSlice> seasonalSlices;

  const _CountryAnalyticsSnapshot({
    required this.eda,
    required this.totalEvents,
    required this.earthquakeCount,
    required this.floodCount,
    required this.weatherCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.maxMagnitude,
    required this.trendLabel,
    required this.trendPercent,
    required this.dominantHazard,
    required this.dominantHazardShare,
    required this.riskLabel,
    required this.riskColor,
    required this.fiveYearAverage,
    required this.seasonalSlices,
  });

  factory _CountryAnalyticsSnapshot.fromEda(CountryEDA eda) {
    final earthquakeCount = eda.earthquakeStats.totalCount;
    final floodCount = eda.floodStats.totalCount;
    final weatherCount = eda.weatherStats.totalCount;
    final totalEvents = earthquakeCount + floodCount + weatherCount;

    final maxMagnitude = [
      eda.earthquakeStats.maxMagnitude,
      eda.floodStats.maxMagnitude,
      eda.weatherStats.maxMagnitude,
    ].fold<double>(0.0, math.max);

    final hazardCounts = <String, int>{
      'Earthquake': earthquakeCount,
      'Flood': floodCount,
      'Weather': weatherCount,
    };
    final dominantEntry = hazardCounts.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final dominantHazardShare = totalEvents == 0
        ? 0.0
        : dominantEntry.value / totalEvents * 100;

    final fiveYearAverage = eda.totalDisastersLast5Years == 0
        ? 0.0
        : eda.totalDisastersLast5Years / 5.0;

    final trendLabel = eda.trendDirection.isEmpty
        ? 'Stable'
        : eda.trendDirection[0].toUpperCase() + eda.trendDirection.substring(1);

    final riskLabel = eda.riskAssessment.overallRiskLevel.isEmpty
        ? 'Unknown'
        : eda.riskAssessment.overallRiskLevel[0].toUpperCase() +
              eda.riskAssessment.overallRiskLevel.substring(1);

    final riskColor = eda.riskAssessment.riskScore >= 65
        ? AppColors.danger
        : eda.riskAssessment.riskScore >= 35
        ? AppColors.warning
        : AppColors.safe;

    final seasonalSlices = eda.seasonalRisks
        .map(
          (seasonal) => _CountrySeasonSlice(
            label: seasonal.season,
            value: seasonal.incidentFrequency,
            riskLevel: seasonal.riskLevel,
            color: _seasonColor(seasonal.riskLevel),
          ),
        )
        .toList();

    final severityHigh =
        eda.earthquakeStats.highRiskCount +
        eda.floodStats.highRiskCount +
        eda.weatherStats.highRiskCount;
    final severityMedium =
        eda.earthquakeStats.mediumRiskCount +
        eda.floodStats.mediumRiskCount +
        eda.weatherStats.mediumRiskCount;
    final severityLow =
        eda.earthquakeStats.lowRiskCount +
        eda.floodStats.lowRiskCount +
        eda.weatherStats.lowRiskCount;

    return _CountryAnalyticsSnapshot(
      eda: eda,
      totalEvents: totalEvents,
      earthquakeCount: earthquakeCount,
      floodCount: floodCount,
      weatherCount: weatherCount,
      highCount: severityHigh,
      mediumCount: severityMedium,
      lowCount: severityLow,
      maxMagnitude: maxMagnitude,
      trendLabel: trendLabel,
      trendPercent: eda.trendPercentage.abs(),
      dominantHazard: dominantEntry.key,
      dominantHazardShare: dominantHazardShare,
      riskLabel: riskLabel,
      riskColor: riskColor,
      fiveYearAverage: fiveYearAverage,
      seasonalSlices: seasonalSlices,
    );
  }
}

class _CountrySeasonSlice {
  final String label;
  final int value;
  final String riskLevel;
  final Color color;

  const _CountrySeasonSlice({
    required this.label,
    required this.value,
    required this.riskLevel,
    required this.color,
  });
}

class _CountryAnalyticsHeroCard extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountryAnalyticsHeroCard({required this.snapshot});

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
                  Icons.public_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.eda.countryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Country risk analytics',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CountryTrendBadge(
                label: snapshot.trendLabel,
                percent: snapshot.trendPercent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            snapshot.totalEvents == 0
                ? 'No disaster records are loaded for this country yet.'
                : '${snapshot.totalEvents} country events are shaping a ${snapshot.riskLabel.toLowerCase()} risk profile, with ${snapshot.dominantHazard.toLowerCase()} leading the mix.',
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
              _CountryHeroChip(
                label:
                    '${snapshot.dominantHazard} ${snapshot.dominantHazardShare.toStringAsFixed(0)}%',
              ),
              _CountryHeroChip(label: 'Risk ${snapshot.riskLabel}'),
              _CountryHeroChip(
                label: '5y avg ${snapshot.fiveYearAverage.toStringAsFixed(1)}',
              ),
            ],
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

class _CountryHeroChip extends StatelessWidget {
  final String label;

  const _CountryHeroChip({required this.label});

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

class _CountryTrendBadge extends StatelessWidget {
  final String label;
  final double percent;

  const _CountryTrendBadge({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized.contains('incre') || normalized.contains('ris')
        ? Colors.orange.shade200
        : normalized.contains('decre') || normalized.contains('cool')
        ? Colors.lightGreen.shade200
        : Colors.white70;
    final icon = normalized.contains('incre') || normalized.contains('ris')
        ? Icons.trending_up_rounded
        : normalized.contains('decre') || normalized.contains('cool')
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

class _CountryMetricGrid extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountryMetricGrid({required this.snapshot});

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
        _CountryMetricCard(
          icon: Icons.public_rounded,
          iconColor: AppColors.primaryDark,
          label: 'Country events',
          value: snapshot.totalEvents.toString(),
        ),
        _CountryMetricCard(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
          label: 'Top hazard share',
          value: '${snapshot.dominantHazardShare.toStringAsFixed(0)}%',
          helper: snapshot.dominantHazard,
        ),
      ],
    );
  }
}

class _CountryMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? helper;

  const _CountryMetricCard({
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

class _CountryYearlyComparisonCard extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountryYearlyComparisonCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(
      snapshot.eda.totalDisastersLastYear.toDouble(),
      snapshot.fiveYearAverage,
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
                'Last year vs 5-year average',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CountryComparisonBar(
                  label: 'Last year',
                  value: snapshot.eda.totalDisastersLastYear.toDouble(),
                  maxValue: maxValue,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 16),
                _CountryComparisonBar(
                  label: '5y avg',
                  value: snapshot.fiveYearAverage,
                  maxValue: maxValue,
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _CountryComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = maxValue == 0 ? 12.0 : 24 + (value / maxValue) * 130;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CountryHazardMixCard extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountryHazardMixCard({required this.snapshot});

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
          _CountryHazardMixRow(
            label: 'Earthquake',
            count: snapshot.earthquakeCount,
            total: snapshot.totalEvents,
            color: AppColors.earthquake,
          ),
          const SizedBox(height: 14),
          _CountryHazardMixRow(
            label: 'Flood',
            count: snapshot.floodCount,
            total: snapshot.totalEvents,
            color: AppColors.flood,
          ),
          const SizedBox(height: 14),
          _CountryHazardMixRow(
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

class _CountryHazardMixRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _CountryHazardMixRow({
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

class _CountrySeverityDonutCard extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountrySeverityDonutCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final slices = [
      _CountryDonutSlice(
        label: 'High',
        value: snapshot.highCount,
        color: AppColors.danger,
      ),
      _CountryDonutSlice(
        label: 'Medium',
        value: snapshot.mediumCount,
        color: AppColors.warning,
      ),
      _CountryDonutSlice(
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
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _CountryDonutChartPainter(slices: slices),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...slices.map(
                  (slice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CountrySeverityLegendRow(
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
    );
  }
}

class _CountryDonutSlice {
  final String label;
  final int value;
  final Color color;

  const _CountryDonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _CountrySeverityLegendRow extends StatelessWidget {
  final _CountryDonutSlice slice;
  final int total;

  const _CountrySeverityLegendRow({required this.slice, required this.total});

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

class _CountryDonutChartPainter extends CustomPainter {
  final List<_CountryDonutSlice> slices;

  _CountryDonutChartPainter({required this.slices});

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
  bool shouldRepaint(covariant _CountryDonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _CountrySeasonalRiskChart extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountrySeasonalRiskChart({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final maxCount = snapshot.seasonalSlices.fold<int>(
      0,
      (maxValue, slice) => math.max(maxValue, slice.value),
    );

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
                child: CustomPaint(
                  painter: _CountryDonutChartPainter(
                    slices: snapshot.seasonalSlices
                        .map(
                          (slice) => _CountryDonutSlice(
                            label: slice.label,
                            value: slice.value,
                            color: slice.color,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...snapshot.seasonalSlices.map(
                      (slice) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CountrySeasonLegendRow(slice: slice),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: snapshot.seasonalSlices.map((slice) {
                final barHeight = maxCount == 0
                    ? 12.0
                    : 24 + (slice.value / maxCount) * 120;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          slice.value.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: slice.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: slice.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slice.label,
                          style: TextStyle(
                            fontSize: 12,
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

class _CountrySeasonLegendRow extends StatelessWidget {
  final _CountrySeasonSlice slice;

  const _CountrySeasonLegendRow({required this.slice});

  @override
  Widget build(BuildContext context) {
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
            '${slice.label} (${slice.riskLevel})',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${slice.value}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _CountryInsightCard extends StatelessWidget {
  final _CountryAnalyticsSnapshot snapshot;

  const _CountryInsightCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final points = <String>[
      if (snapshot.totalEvents == 0)
        'No country-level disaster records are loaded yet, so the dashboard will remain empty until data is available.',
      if (snapshot.totalEvents > 0)
        '${snapshot.dominantHazard} is the leading hazard type, contributing ${snapshot.dominantHazardShare.toStringAsFixed(0)}% of the selected country’s events.',
      'The country is currently rated ${snapshot.riskLabel.toLowerCase()} with a score of ${snapshot.eda.riskAssessment.riskScore.toStringAsFixed(0)}.',
      'Last year recorded ${snapshot.eda.totalDisastersLastYear} events versus a 5-year average of ${snapshot.fiveYearAverage.toStringAsFixed(1)}.',
      'Peak seasonal frequency appears in ${snapshot.seasonalSlices.reduce((left, right) => left.value >= right.value ? left : right).label}.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: points
            .map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CountryInsightRow(text: point),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CountryInsightRow extends StatelessWidget {
  final String text;

  const _CountryInsightRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.aiAccent, size: 16),
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

Color _seasonColor(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
      return AppColors.danger;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.safe;
  }
}

class _CountryHeaderCard extends StatelessWidget {
  final CountryEDA eda;

  const _CountryHeaderCard({required this.eda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eda.countryName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderInfo(
                label: AppStrings.populationData,
                value: eda.population != null
                    ? '${(eda.population! / 1000000).toStringAsFixed(1)}M'
                    : 'N/A',
              ),
              const SizedBox(width: 24),
              _HeaderInfo(
                label: AppStrings.areaData,
                value: '${(eda.areaSqKm / 1000).toStringAsFixed(1)}K km²',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RiskAssessmentCard extends StatelessWidget {
  final RiskAssessment risk;

  const _RiskAssessmentCard({required this.risk});

  Color _getRiskColor() {
    switch (risk.overallRiskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.overallRiskLevel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      risk.overallRiskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getRiskColor(),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.riskScore,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${risk.riskScore.toStringAsFixed(1)}/100',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RiskProgressBar(score: risk.riskScore),
          const SizedBox(height: 16),
          Text(
            AppStrings.primaryHazard,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            risk.primaryHazard,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (risk.lastMajorEvent != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.lastMajorEvent,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${risk.daysSinceEvent ?? 0} days ago',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskProgressBar extends StatelessWidget {
  final double score;

  const _RiskProgressBar({required this.score});

  Color _getColorForScore(double score) {
    if (score < 25) return Colors.green;
    if (score < 50) return Colors.amber;
    if (score < 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForScore(score),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisasterStatsCard extends StatelessWidget {
  final String title;
  final DisasterStats stats;
  final Color color;

  const _DisasterStatsCard({
    required this.title,
    required this.stats,
    required this.color,
  });

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Total Events', value: stats.totalCount.toString()),
          _StatRow(
            label: 'Maximum',
            value: stats.maxMagnitude.toStringAsFixed(1),
          ),
          _StatRow(
            label: 'Recent (30 days)',
            value: stats.recentCount.toString(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RiskCountBadge(
                label: 'High',
                count: stats.highRiskCount,
                color: Colors.red,
              ),
              _RiskCountBadge(
                label: 'Medium',
                count: stats.mediumRiskCount,
                color: Colors.orange,
              ),
              _RiskCountBadge(
                label: 'Low',
                count: stats.lowRiskCount,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RiskCountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricalDataCard extends StatelessWidget {
  final CountryEDA eda;

  const _HistoricalDataCard({required this.eda});

  @override
  Widget build(BuildContext context) {
    final trend = eda.trendDirection.toLowerCase();
    final trendIcon = trend == 'increasing'
        ? Icons.trending_up
        : trend == 'decreasing'
        ? Icons.trending_down
        : Icons.trending_flat;
    final trendColor = trend == 'increasing' ? Colors.red : Colors.green;

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
          _StatRow(
            label: AppStrings.disastersLastYear,
            value: eda.totalDisastersLastYear.toString(),
          ),
          _StatRow(
            label: AppStrings.disastersLast5Years,
            value: eda.totalDisastersLast5Years.toString(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.trendDirection,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${eda.trendDirection} (${eda.trendPercentage > 0 ? '+' : ''}${eda.trendPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonalRiskCard extends StatelessWidget {
  final CountrySeasonalRisk seasonal;

  const _SeasonalRiskCard({required this.seasonal});

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                seasonal.season.replaceFirst(
                  seasonal.season[0],
                  seasonal.season[0].toUpperCase(),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRiskColor(seasonal.riskLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  seasonal.riskLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getRiskColor(seasonal.riskLevel),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: seasonal.primaryHazards
                .map(
                  (hazard) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hazard,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.incidentFrequency}: ${seasonal.incidentFrequency} per month',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String recommendation;
  final int index;

  const _RecommendationCard({
    required this.recommendation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
