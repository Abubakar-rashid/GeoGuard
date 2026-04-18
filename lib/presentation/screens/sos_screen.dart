import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen> {
  bool _isHolding = false;
  double _holdProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final emergencyContacts = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SOS Header with Button
            _SOSHeader(
              isHolding: _isHolding,
              holdProgress: _holdProgress,
              onHoldStart: () => setState(() => _isHolding = true),
              onHoldEnd: () => setState(() {
                _isHolding = false;
                _holdProgress = 0.0;
              }),
              onSOSTriggered: _triggerSOS,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // What happens info card
                  _InfoCard(),
                  const SizedBox(height: 20),

                  // Emergency Contacts Section
                  const Text(
                    AppStrings.emergencyContacts,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Emergency Services
                  _EmergencyContactCard(
                    contact: const EmergencyContact(
                      id: 'emergency_services',
                      name: 'Emergency Services',
                      phoneNumber: '911',
                      isEmergencyService: true,
                    ),
                    isEmergencyService: true,
                  ),
                  const SizedBox(height: 8),

                  // User's Emergency Contacts
                  emergencyContacts.when(
                    data: (contacts) => Column(
                      children: contacts
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _EmergencyContactCard(contact: c),
                              ))
                          .toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Unable to load contacts'),
                  ),

                  // Demo contacts for UI
                  _EmergencyContactCard(
                    contact: const EmergencyContact(
                      id: 'demo1',
                      name: 'John Doe',
                      phoneNumber: '+1 234 567 8900',
                      relationship: 'Emergency',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _EmergencyContactCard(
                    contact: const EmergencyContact(
                      id: 'demo2',
                      name: 'Jane Smith',
                      phoneNumber: '+1 234 567 8901',
                      relationship: 'Family',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Share Live Location Button
                  _ShareLocationButton(),
                  const SizedBox(height: 24),

                  // Nearby Hospitals Section
                  const Text(
                    AppStrings.nearbyHospitals,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hospital List (demo data)
                  _HospitalCard(
                    hospital: Hospital(
                      id: 'h1',
                      name: 'City General Hospital',
                      latitude: 0,
                      longitude: 0,
                      distanceKm: 2.3,
                      estimatedDriveMinutes: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HospitalCard(
                    hospital: Hospital(
                      id: 'h2',
                      name: 'Emergency Medical Center',
                      latitude: 0,
                      longitude: 0,
                      distanceKm: 3.8,
                      estimatedDriveMinutes: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HospitalCard(
                    hospital: Hospital(
                      id: 'h3',
                      name: "St. Mary's Hospital",
                      latitude: 0,
                      longitude: 0,
                      distanceKm: 5.1,
                      estimatedDriveMinutes: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Emergency Tips
                  _EmergencyTipsCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSOS() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert Sent!'),
        content: const Text(
          'Your emergency contacts have been notified with your location. '
          'Emergency services will be contacted shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SOSHeader extends StatefulWidget {
  final bool isHolding;
  final double holdProgress;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onSOSTriggered;

  const _SOSHeader({
    required this.isHolding,
    required this.holdProgress,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onSOSTriggered,
  });

  @override
  State<_SOSHeader> createState() => _SOSHeaderState();
}

class _SOSHeaderState extends State<_SOSHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      if (_controller.isCompleted) {
        widget.onSOSTriggered();
        _controller.reset();
        widget.onHoldEnd();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    widget.onHoldStart();
    _controller.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _controller.reset();
    widget.onHoldEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: AppColors.sosRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                tooltip: 'Back',
              ),
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress indicator
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: _controller.value,
                              strokeWidth: 4,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          // SOS Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.emergencySOS,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.pressAndHold,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.whatHappens,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _BulletPoint(text: 'Your location is shared with emergency contacts'),
          const _BulletPoint(text: 'Emergency services will be notified'),
          const _BulletPoint(text: "You'll get 5 seconds to cancel"),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final bool isEmergencyService;

  const _EmergencyContactCard({
    required this.contact,
    this.isEmergencyService = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmergencyService ? AppColors.sosRed.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmergencyService ? AppColors.sosRed.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmergencyService ? AppColors.sosRed : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmergencyService ? Icons.phone : Icons.person_outline,
              color: isEmergencyService ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  contact.relationship != null
                      ? '${contact.phoneNumber}'
                      : contact.phoneNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _makePhoneCall(contact.phoneNumber),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Call',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}

class _ShareLocationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            AppStrings.shareLiveLocation,
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

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;

  const _HospitalCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_hospital, color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${hospital.distanceDisplay}  •  ${hospital.driveTimeDisplay}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Navigate to hospital
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Navigate',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.emergencyTips,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const _BulletPoint(text: 'Stay calm and assess the situation'),
          const _BulletPoint(text: 'Move to a safe location if possible'),
          const _BulletPoint(text: 'Keep your phone charged'),
          const _BulletPoint(text: 'Follow instructions from authorities'),
        ],
      ),
    );
  }
}
