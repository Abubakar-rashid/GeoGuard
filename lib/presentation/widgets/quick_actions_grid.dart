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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
