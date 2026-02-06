import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyState = ref.watch(safetyStateProvider);
    final disasters = ref.watch(allDisastersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const HomeHeader(),
              const SizedBox(height: 20),

              // Safety Status Card
              safetyState.when(
                data: (state) => SafetyStatusCard(safetyState: state),
                loading: () => const SafetyStatusCardLoading(),
                error: (_, __) => const SafetyStatusCard(
                  safetyState: SafetyState(
                    status: SafetyStatus.safe,
                    message: 'Unable to determine status',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                AppStrings.quickActions,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const QuickActionsGrid(),
              const SizedBox(height: 24),

              // Recent Alerts Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.recentAlerts,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all alerts
                    },
                    child: const Text(
                      AppStrings.viewAll,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Alerts List
              disasters.when(
                data: (list) => RecentAlertsList(disasters: list.take(3).toList()),
                loading: () => const RecentAlertsLoading(),
                error: (_, __) => const Center(
                  child: Text('Unable to load alerts'),
                ),
              ),
              const SizedBox(height: 16),

              // AI Safety Assistant Card
              const AIAssistantCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              AppStrings.appSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            // Open notifications
          },
          icon: const Icon(
            Icons.notifications_outlined,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
