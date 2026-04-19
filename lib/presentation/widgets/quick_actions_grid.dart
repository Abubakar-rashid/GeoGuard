import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../screens/screens.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _QuickActionCard(
          icon: Icons.map_outlined,
          iconColor: AppColors.flood,
          backgroundColor: AppColors.mapCardBg,
          title: AppStrings.liveMap,
          subtitle: AppStrings.viewThreats,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.warning_amber_outlined,
          iconColor: AppColors.danger,
          backgroundColor: AppColors.emergencyCardBg,
          title: AppStrings.emergency,
          subtitle: AppStrings.sendSOS,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SOSScreen()),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.menu_book_outlined,
          iconColor: AppColors.warning,
          backgroundColor: AppColors.survivalCardBg,
          title: AppStrings.survivalGuide,
          subtitle: AppStrings.learnSafety,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SurvivalGuideScreen()),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.trending_up,
          iconColor: AppColors.weather,
          backgroundColor: AppColors.analysisCardBg,
          title: AppStrings.riskAnalysis,
          subtitle: AppStrings.viewTrends,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiskAnalysisScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Container(height: 4, color: iconColor.withOpacity(0.9)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: backgroundColor.withOpacity(0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: iconColor.withOpacity(0.18),
                              ),
                            ),
                            child: Icon(icon, color: iconColor, size: 28),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Open',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: iconColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
