import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushNotifications = ref.watch(pushNotificationsProvider);
    final locationTracking = ref.watch(locationTrackingProvider);
    final darkMode = ref.watch(darkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.settings),
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
            // User Profile Card
            _UserProfileCard(),
            const SizedBox(height: 24),

            // Alerts & Notifications Section
            _SectionHeader(title: AppStrings.alertsNotifications),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsToggleTile(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.pushNotifications,
                  value: pushNotifications,
                  onChanged: (value) {
                    ref.read(pushNotificationsProvider.notifier).state = value;
                  },
                ),
                const Divider(height: 1),
                _SettingsNavTile(
                  icon: Icons.notifications_active_outlined,
                  title: AppStrings.alertSensitivity,
                  subtitle: 'Medium',
                  onTap: () {
                    // Navigate to alert sensitivity settings
                  },
                ),
                const Divider(height: 1),
                _SettingsToggleTile(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.locationTracking,
                  value: locationTracking,
                  onChanged: (value) {
                    ref.read(locationTrackingProvider.notifier).state = value;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Area & Preferences Section
            _SectionHeader(title: AppStrings.areaPreferences),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsNavTile(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.yourLocation2,
                  subtitle: 'San Francisco, CA',
                  onTap: () {
                    // Navigate to location settings
                  },
                ),
                const Divider(height: 1),
                _SettingsNavTile(
                  icon: Icons.download_outlined,
                  title: AppStrings.offlineDownloads,
                  subtitle: '3 guides',
                  onTap: () {
                    // Navigate to offline downloads
                  },
                ),
                const Divider(height: 1),
                _SettingsToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: AppStrings.darkMode,
                  value: darkMode,
                  onChanged: (value) {
                    ref.read(darkModeProvider.notifier).state = value;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Section
            _SectionHeader(title: AppStrings.emergencyContacts),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsNavTile(
                  icon: Icons.people_outline,
                  title: AppStrings.manageContacts,
                  subtitle: '2 contacts',
                  onTap: () {
                    // Navigate to manage contacts
                  },
                ),
                const Divider(height: 1),
                _SettingsToggleTile(
                  icon: Icons.share_location_outlined,
                  title: AppStrings.autoShareLocation,
                  value: true,
                  onChanged: (value) {
                    // Handle auto-share location toggle
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Support & Info Section
            _SectionHeader(title: AppStrings.supportInfo),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsNavTile(
                  icon: Icons.help_outline,
                  title: AppStrings.helpFaq,
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsNavTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.privacyPolicy,
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsNavTile(
                  icon: Icons.description_outlined,
                  title: AppStrings.termsOfService,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Version
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Version ${AppStrings.appVersion} • Build ${AppStrings.buildNumber}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sign Out Button
            _SignOutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'john.doe@email.com',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsNavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Text(
            AppStrings.signOut,
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
