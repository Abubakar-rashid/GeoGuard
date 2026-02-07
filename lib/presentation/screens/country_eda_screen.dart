import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class CountryEdaScreen extends ConsumerStatefulWidget {
  const CountryEdaScreen({super.key});

  @override
  ConsumerState<CountryEdaScreen> createState() => _CountryEdaScreenState();
}

class _CountryEdaScreenState extends ConsumerState<CountryEdaScreen> {
  late TextEditingController _searchController;
  String? _selectedCountry;
  List<String> _searchSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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

    final suggestions =
        await ref.read(countrySearchProvider(query).future);
    setState(() {
      _searchSuggestions = suggestions;
      _isSearching = false;
    });
  }

  void _selectCountry(String country) {
    setState(() {
      _selectedCountry = country;
      _searchController.text = country;
      _searchSuggestions = [];
    });
    ref.read(selectedCountryProvider.notifier).state = country;
  }

  @override
  Widget build(BuildContext context) {
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
            if (_selectedCountry != null)
              _buildCountryEDAView(_selectedCountry!)
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
                        Icon(Icons.location_on,
                            size: 18, color: Colors.grey.shade600),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          color: Colors.purple,
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
            Icon(
              Icons.public,
              size: 60,
              color: Colors.grey.shade400,
            ),
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
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
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
                  _selectedCountry = null;
                  _searchController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getColorForScore(score)),
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
          _StatRow(
            label: 'Total Events',
            value: stats.totalCount.toString(),
          ),
          _StatRow(
            label: 'Average Magnitude',
            value: stats.averageMagnitude.toStringAsFixed(1),
          ),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
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
                    seasonal.season[0], seasonal.season[0].toUpperCase()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
