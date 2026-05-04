import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class GuideDetailScreen extends StatelessWidget {
  final String title;
  final int stepsCount;
  final List<String> relatedGuides;
  final bool isOffline;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.stepsCount,
    required this.relatedGuides,
    required this.isOffline,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final steps = List.generate(stepsCount, (i) => _sampleStep(i + 1));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('$stepsCount essential steps • ${isOffline ? 'Available offline' : 'Online only'}', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder: download or toggle offline
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded for offline use')));
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text('Quick Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              _overviewText(title),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            const Text('Steps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...steps.map((s) => _StepTile(step: s)),
            const SizedBox(height: 16),

            if (relatedGuides.isNotEmpty) ...[
              const Text('Related Guides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: relatedGuides.map((g) => Chip(label: Text(g))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _overviewText(String title) {
    return 'This guide provides essential actions and safety measures to follow during "$title". Follow the numbered steps to prepare, respond, and recover.';
  }

  static Map<String, String> _sampleStep(int step) {
    return {
      'title': 'Step $step',
      'description': 'Detailed instructions for step $step. Ensure you follow local guidance and prioritize safety.'
    };
  }
}

class _StepTile extends StatelessWidget {
  final Map<String, String> step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade100,
            child: Text(step['title']!.split(' ').last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(step['description']!, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
