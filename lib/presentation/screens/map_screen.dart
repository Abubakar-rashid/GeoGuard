import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/constants.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 10.0;

  @override
  Widget build(BuildContext context) {
    final userLocation = ref.watch(userLocationProvider);
    final disasters = ref.watch(filteredDisastersProvider);
    final selectedTypes = ref.watch(selectedDisasterTypesProvider);
    final earthquakeRisk = ref.watch(earthquakeRiskProvider);
    final isCheckingRisk = ref.watch(isCheckingRiskProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.liveHazardMap),
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          userLocation.when(
            data: (location) {
              final center = location != null
                  ? LatLng(location.latitude, location.longitude)
                  : const LatLng(37.7749, -122.4194); // Default to San Francisco

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _currentZoom,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                    enableMultiFingerGestureRace: true,
                    pinchZoomThreshold: 0.3,
                    scrollWheelVelocity: 0.005,
                  ),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.zoom != null) {
                      _currentZoom = position.zoom!;
                    }
                  },
                ),
                children: [
                  // OpenStreetMap Tiles with better caching
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoguard.app',
                    maxZoom: 19,
                    keepBuffer: 5,
                    panBuffer: 3,
                    tileProvider: CancellableNetworkTileProvider(),
                    tileBuilder: (context, tileWidget, tile) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: tileWidget,
                      );
                    },
                  ),

                  // Disaster Circles
                  disasters.when(
                    data: (disasterList) => CircleLayer(
                      circles: disasterList.map((disaster) {
                        return CircleMarker(
                          point: LatLng(disaster.latitude, disaster.longitude),
                          radius: _calculateCircleRadius(disaster.radiusKm),
                          color: _getSeverityColor(disaster.severity).withOpacity(0.3),
                          borderColor: _getSeverityColor(disaster.severity),
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    loading: () => const CircleLayer(circles: []),
                    error: (_, __) => const CircleLayer(circles: []),
                  ),

                  // Earthquake Risk Circles (from Check Risk)
                  if (earthquakeRisk != null)
                    CircleLayer(
                      circles: earthquakeRisk.earthquakes.map((eq) {
                        // Calculate radius based on magnitude (bigger magnitude = bigger circle)
                        final radius = eq.magnitude * 8; // Scale factor for visibility
                        return CircleMarker(
                          point: LatLng(eq.latitude, eq.longitude),
                          radius: radius,
                          color: _getEarthquakeRiskColor(eq.severity).withOpacity(0.4),
                          borderColor: _getEarthquakeRiskColor(eq.severity),
                          borderStrokeWidth: 3,
                        );
                      }).toList(),
                    ),

                  // Disaster Markers
                  disasters.when(
                    data: (disasterList) => MarkerLayer(
                      markers: [
                        // User location marker
                        if (location != null)
                          Marker(
                            point: LatLng(location.latitude, location.longitude),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        // Disaster markers
                        ...disasterList.map((disaster) => Marker(
                              point: LatLng(disaster.latitude, disaster.longitude),
                              width: 40,
                              height: 40,
                              child: _DisasterMarkerIcon(disaster: disaster),
                            )),
                      ],
                    ),
                    loading: () => const MarkerLayer(markers: []),
                    error: (_, __) => const MarkerLayer(markers: []),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading map')),
          ),

          // Filter Chips
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: AppStrings.earthquakeFilter,
                    icon: Icons.public,
                    color: AppColors.earthquake,
                    isSelected: selectedTypes.contains(DisasterType.earthquake),
                    onTap: () => _toggleFilter(ref, DisasterType.earthquake),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.floodFilter,
                    icon: Icons.water_drop,
                    color: AppColors.flood,
                    isSelected: selectedTypes.contains(DisasterType.flood),
                    onTap: () => _toggleFilter(ref, DisasterType.flood),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.weatherFilter,
                    icon: Icons.cloud,
                    color: AppColors.weather,
                    isSelected: selectedTypes.contains(DisasterType.weather),
                    onTap: () => _toggleFilter(ref, DisasterType.weather),
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Severity',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(color: AppColors.severityHigh, label: 'High'),
                  const SizedBox(height: 4),
                  _LegendItem(color: AppColors.severityMedium, label: 'Medium'),
                  const SizedBox(height: 4),
                  _LegendItem(color: AppColors.severityLow, label: 'Low'),
                ],
              ),
            ),
          ),

          // Your Location Label
          Positioned(
            top: 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.pink.shade400, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    AppStrings.yourLocation,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  onPressed: () {
                    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
                    _animatedMapMove(_mapController.camera.center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
                    _animatedMapMove(_mapController.camera.center, newZoom);
                  },
                ),
              ],
            ),
          ),

          // Nearest Threat Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 80,
            child: disasters.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                final nearest = list.first;
                return _NearestThreatCard(disaster: nearest);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Navigate to current location
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                final location = ref.read(userLocationProvider).valueOrNull;
                if (location != null) {
                  _animatedMapMove(
                    LatLng(location.latitude, location.longitude),
                    _currentZoom,
                  );
                }
              },
              child: const Icon(Icons.navigation, color: AppColors.primary),
            ),
          ),

          // Earthquake Risk Results Panel
          if (earthquakeRisk != null)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: _EarthquakeRiskPanel(
                riskData: earthquakeRisk,
                onClose: () {
                  ref.read(earthquakeRiskProvider.notifier).state = null;
                },
                onEarthquakeTap: (eq) {
                  _animatedMapMove(LatLng(eq.latitude, eq.longitude), 8);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Check earthquake risk for user's location
  Future<void> _checkEarthquakeRisk(BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
      return;
    }

    ref.read(isCheckingRiskProvider.notifier).state = true;

    try {
      final disasterService = ref.read(disasterServiceProvider);
      final result = await disasterService.checkEarthquakeRisk(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: 500,
        minMagnitude: 4.0,
        days: 7,
      );

      ref.read(earthquakeRiskProvider.notifier).state = result;

      if (result != null && result.earthquakeCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${result.earthquakeCount} earthquake(s) near you!'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No significant earthquakes found nearby in the last 7 days'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking risk: $e')),
      );
    } finally {
      ref.read(isCheckingRiskProvider.notifier).state = false;
    }
  }

  void _toggleFilter(WidgetRef ref, DisasterType type) {
    final current = ref.read(selectedDisasterTypesProvider);
    final newSet = Set<DisasterType>.from(current);
    if (newSet.contains(type)) {
      newSet.remove(type);
    } else {
      newSet.add(type);
    }
    ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
  }

  /// Animated map move for smooth transitions
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentZoom = destZoom;
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  double _calculateCircleRadius(double radiusKm) {
    // Convert km to pixels based on zoom level
    return radiusKm * 1000 / (40075016.686 / (256 * (1 << _currentZoom.toInt())));
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.high:
        return AppColors.severityHigh;
      case SeverityLevel.medium:
        return AppColors.severityMedium;
      case SeverityLevel.low:
        return AppColors.severityLow;
    }
  }

  Color _getEarthquakeRiskColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.orange;
    }
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

class _DisasterMarkerIcon extends StatelessWidget {
  final Disaster disaster;

  const _DisasterMarkerIcon({required this.disaster});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color bgColor;

    switch (disaster.type) {
      case DisasterType.earthquake:
        icon = Icons.public;
        bgColor = AppColors.earthquake;
        break;
      case DisasterType.flood:
        icon = Icons.water_drop;
        bgColor = AppColors.flood;
        break;
      case DisasterType.weather:
        icon = Icons.cloud;
        bgColor = AppColors.weather;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}

class _NearestThreatCard extends StatelessWidget {
  final Disaster disaster;

  const _NearestThreatCard({required this.disaster});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.nearestThreat,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${disaster.distanceFromUser?.toStringAsFixed(0) ?? '--'} km • ${disaster.severity.name.toUpperCase()} Risk',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Disasters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Add more filter options here
          const Text('More filter options coming soon...'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Panel showing earthquake risk results
class _EarthquakeRiskPanel extends StatelessWidget {
  final EarthquakeRiskResponse riskData;
  final VoidCallback onClose;
  final Function(EarthquakeRisk) onEarthquakeTap;

  const _EarthquakeRiskPanel({
    required this.riskData,
    required this.onClose,
    required this.onEarthquakeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskData.earthquakeCount > 0 ? Colors.orange : Colors.green,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  riskData.earthquakeCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    riskData.earthquakeCount > 0
                        ? '${riskData.earthquakeCount} Earthquake(s) Found'
                        : 'No Earthquakes Found',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          if (riskData.earthquakes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No significant earthquakes (magnitude ≥ 4.0) detected within 500km in the last 7 days.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: riskData.earthquakes.length,
                itemBuilder: (context, index) {
                  final eq = riskData.earthquakes[index];
                  return _EarthquakeListItem(
                    earthquake: eq,
                    onTap: () => onEarthquakeTap(eq),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Individual earthquake item in the risk panel
class _EarthquakeListItem extends StatelessWidget {
  final EarthquakeRisk earthquake;
  final VoidCallback onTap;

  const _EarthquakeListItem({
    required this.earthquake,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = earthquake.dateTime;
    final timeStr = dateTime != null
        ? '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
        : 'Unknown time';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Magnitude indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getSeverityColor(earthquake.severity).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(earthquake.severity),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  earthquake.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(earthquake.severity),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earthquake.place,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${earthquake.distanceFromUser.toStringAsFixed(0)} km away',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.orange;
    }
  }
}

