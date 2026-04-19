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
      childAspectRatio: 1.12,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: iconColor.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(icon, color: iconColor, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
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
