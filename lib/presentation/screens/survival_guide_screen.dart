import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';

class SurvivalGuideScreen extends ConsumerStatefulWidget {
  const SurvivalGuideScreen({super.key});

  @override
  ConsumerState<SurvivalGuideScreen> createState() => _SurvivalGuideScreenState();
}

class _SurvivalGuideScreenState extends ConsumerState<SurvivalGuideScreen> {
  bool _offlineMode = true;

  // Demo data for guides
  final List<_GuideCategory> _categories = [
    _GuideCategory(
      title: 'Earthquake Safety',
      steps: 6,
      isOffline: true,
      icon: Icons.public,
      iconBgColor: Colors.green.shade100,
      iconColor: Colors.green.shade700,
    ),
    _GuideCategory(
      title: 'Flood Preparedness',
      steps: 7,
      isOffline: true,
      icon: Icons.water_drop,
      iconBgColor: Colors.blue.shade100,
      iconColor: Colors.blue.shade700,
    ),
    _GuideCategory(
      title: 'Severe Weather',
      steps: 5,
      isOffline: true,
      icon: Icons.cloud,
      iconBgColor: Colors.purple.shade100,
      iconColor: Colors.purple.shade700,
    ),
    _GuideCategory(
      title: 'First Aid Basics',
      steps: 8,
      isOffline: false,
      icon: Icons.medical_services,
      iconBgColor: Colors.red.shade100,
      iconColor: Colors.red.shade700,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.survivalManual),
            Text(
              AppStrings.offlineGuides,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // Download all guides
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline Mode Toggle
            _OfflineModeCard(
              isEnabled: _offlineMode,
              onToggle: (value) => setState(() => _offlineMode = value),
            ),
            const SizedBox(height: 24),

            // Browse Categories
            const Text(
              AppStrings.browseCategories,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Category List
            ...List.generate(_categories.length, (index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryCard(category: category),
              );
            }),
            const SizedBox(height: 24),

            // Quick Safety Tips
            const Text(
              AppStrings.quickSafetyTips,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _SafetyTipCard(
              title: 'Emergency Kit',
              description: 'Keep water, food, flashlight, batteries, and first aid supplies ready.',
              borderColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _SafetyTipCard(
              title: 'Communication Plan',
              description: 'Establish a family meeting point and emergency contact list.',
              borderColor: Colors.blue,
            ),
            const SizedBox(height: 8),
            _SafetyTipCard(
              title: 'Stay Informed',
              description: 'Enable push notifications for real-time disaster alerts in your area.',
              borderColor: Colors.green,
            ),
            const SizedBox(height: 24),

            // Download All Button
            _DownloadAllButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _GuideCategory {
  final String title;
  final int steps;
  final bool isOffline;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  _GuideCategory({
    required this.title,
    required this.steps,
    required this.isOffline,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}

class _OfflineModeCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _OfflineModeCard({required this.isEnabled, required this.onToggle});

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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_download, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.offlineMode,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Available without internet',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _GuideCategory category;

  const _CategoryCard({required this.category});

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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.steps} essential steps',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (category.isOffline) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.download_done, color: Colors.green.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Available offline',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SafetyTipCard extends StatelessWidget {
  final String title;
  final String description;
  final Color borderColor;

  const _SafetyTipCard({
    required this.title,
    required this.description,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _DownloadAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            AppStrings.downloadAllGuides,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
