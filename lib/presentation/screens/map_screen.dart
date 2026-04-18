import 'dart:math';
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
  bool _riskPanelExpanded = true; // controls whether the info panel detail is visible

  @override
  void initState() {
    super.initState();
    // Auto-trigger earthquake risk check on first load if earthquake filter is already selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedTypes = ref.read(selectedDisasterTypesProvider);
      if (selectedTypes.contains(DisasterType.earthquake)) {
        _checkEarthquakeRisk(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = ref.watch(userLocationProvider);
    final disasters = ref.watch(filteredDisastersProvider);
    final selectedTypes = ref.watch(selectedDisasterTypesProvider);
    final earthquakeRisk = ref.watch(earthquakeRiskProvider);
    final isCheckingRisk = ref.watch(isCheckingRiskProvider);
    final floodRisk = ref.watch(floodRiskProvider);
    final isCheckingFloodRisk = ref.watch(isCheckingFloodRiskProvider);
    final weatherRisk = ref.watch(weatherRiskProvider);
    final isCheckingWeatherRisk = ref.watch(isCheckingWeatherRiskProvider);

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
                  // OpenStreetMap Tiles — no AnimatedSwitcher for smooth panning
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoguard.app',
                    maxZoom: 19,
                    keepBuffer: 8,
                    panBuffer: 5,
                    tileProvider: CancellableNetworkTileProvider(),
                  ),

                  // Disaster Circles
                  disasters.when(
                    data: (disasterList) => CircleLayer(
                      circles: disasterList.map((disaster) {
                        return CircleMarker(
                          point: LatLng(disaster.latitude, disaster.longitude),
                          radius: _calculateCircleRadius(disaster.radiusKm),
                          color: _getSeverityColor(disaster.severity).withValues(alpha: 0.3),
                          borderColor: _getSeverityColor(disaster.severity),
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    loading: () => const CircleLayer(circles: []),
                    error: (e, s) => const CircleLayer(circles: []),
                  ),

                  // Earthquake Risk Circles (from Check Risk) — radius in metres
                  if (earthquakeRisk != null && earthquakeRisk.earthquakes.isNotEmpty)
                    CircleLayer(
                      circles: earthquakeRisk.earthquakes.map((eq) {
                        // Circle radius: magnitude * 30 km, converted to metres
                        final radiusMetres = eq.magnitude * 30 * 1000;
                        return CircleMarker(
                          point: LatLng(eq.latitude, eq.longitude),
                          radius: radiusMetres,
                          useRadiusInMeter: true,
                          color: _getEarthquakeRiskColor(eq.severity).withValues(alpha: 0.25),
                          borderColor: _getEarthquakeRiskColor(eq.severity),
                          borderStrokeWidth: 2,
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
                                    color: AppColors.primary.withValues(alpha: 0.3),
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
                    error: (e, s) => const MarkerLayer(markers: []),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Center(child: Text('Error loading map')),
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
                    label: isCheckingRisk && selectedTypes.contains(DisasterType.earthquake)
                        ? 'Checking...'
                        : AppStrings.earthquakeFilter,
                    icon: isCheckingRisk && selectedTypes.contains(DisasterType.earthquake)
                        ? Icons.hourglass_top
                        : Icons.public,
                    color: AppColors.earthquake,
                    isSelected: selectedTypes.contains(DisasterType.earthquake),
                    onTap: () => _handleEarthquakeChipTap(context, ref),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: isCheckingFloodRisk && selectedTypes.contains(DisasterType.flood)
                        ? 'Checking...'
                        : AppStrings.floodFilter,
                    icon: isCheckingFloodRisk && selectedTypes.contains(DisasterType.flood)
                        ? Icons.hourglass_top
                        : Icons.water_drop,
                    color: AppColors.flood,
                    isSelected: selectedTypes.contains(DisasterType.flood),
                    onTap: () => _handleFloodChipTap(context, ref),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: isCheckingWeatherRisk && selectedTypes.contains(DisasterType.weather)
                        ? 'Checking...'
                        : AppStrings.weatherFilter,
                    icon: isCheckingWeatherRisk && selectedTypes.contains(DisasterType.weather)
                        ? Icons.hourglass_top
                        : Icons.cloud,
                    color: AppColors.weather,
                    isSelected: selectedTypes.contains(DisasterType.weather),
                    onTap: () => _handleWeatherChipTap(context, ref),
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                    color: Colors.black.withValues(alpha: 0.1),
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

          // Nearest Threat Card — hidden when any risk panel is open
          if (earthquakeRisk == null && floodRisk == null && weatherRisk == null)
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
                error: (e, s) => const SizedBox.shrink(),
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
              bottom: 75,
              left: 16,
              right: 16,
              child: _EarthquakeRiskPanel(
                riskData: earthquakeRisk,
                isExpanded: _riskPanelExpanded,
                onToggleExpand: () {
                  setState(() => _riskPanelExpanded = !_riskPanelExpanded);
                },
                onClose: () {
                  ref.read(earthquakeRiskProvider.notifier).state = null;
                  setState(() => _riskPanelExpanded = true);
                },
                onEarthquakeTap: (eq) {
                  _animatedMapMove(LatLng(eq.latitude, eq.longitude), 8);
                },
              ),
            ),

          // Flood Risk Results Panel — collapsible timeline
          if (floodRisk != null)
            Positioned(
              bottom: 75,
              left: 16,
              right: 16,
              child: _FloodRiskPanel(
                riskData: floodRisk,
                isExpanded: _riskPanelExpanded,
                onToggleExpand: () {
                  setState(() => _riskPanelExpanded = !_riskPanelExpanded);
                },
                onClose: () {
                  ref.read(floodRiskProvider.notifier).state = null;
                  final current = ref.read(selectedDisasterTypesProvider);
                  final newSet = Set<DisasterType>.from(current)
                    ..remove(DisasterType.flood);
                  ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
                  setState(() => _riskPanelExpanded = true);
                },
              ),
            ),

          // Weather Risk Results Panel — collapsible 5-day forecast
          if (weatherRisk != null)
            Positioned(
              bottom: 75,
              left: 16,
              right: 16,
              child: _WeatherRiskPanel(
                riskData: weatherRisk,
                isExpanded: _riskPanelExpanded,
                onToggleExpand: () {
                  setState(() => _riskPanelExpanded = !_riskPanelExpanded);
                },
                onClose: () {
                  ref.read(weatherRiskProvider.notifier).state = null;
                  final current = ref.read(selectedDisasterTypesProvider);
                  final newSet = Set<DisasterType>.from(current)
                    ..remove(DisasterType.weather);
                  ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
                  setState(() => _riskPanelExpanded = true);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Check earthquake risk for user's location (1000 km radius)
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
        radiusKm: 1000,
        minMagnitude: 4.0,
        days: 7,
      );

      ref.read(earthquakeRiskProvider.notifier).state = result;

      if (result != null && result.threatDetected && result.earthquakes.isNotEmpty) {
        // Auto-zoom map to fit all earthquake circles
        double minLat = location.latitude;
        double maxLat = location.latitude;
        double minLon = location.longitude;
        double maxLon = location.longitude;

        for (final eq in result.earthquakes) {
          minLat = min(minLat, eq.latitude);
          maxLat = max(maxLat, eq.latitude);
          minLon = min(minLon, eq.longitude);
          maxLon = max(maxLon, eq.longitude);
        }

        final centerLat = (minLat + maxLat) / 2;
        final centerLon = (minLon + maxLon) / 2;
        _animatedMapMove(LatLng(centerLat, centerLon), 5.0);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${result.earthquakeCount} earthquake(s) detected within 1000 km!'),
              backgroundColor: Colors.deepOrange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ No significant earthquake risk within 1000 km'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking risk: $e')),
        );
      }
    } finally {
      ref.read(isCheckingRiskProvider.notifier).state = false;
    }
  }

  /// Dedicated handler for the earthquake chip:
  /// - First tap: immediately selects the chip and starts the check in one action.
  /// - Subsequent taps while already selected: deselects and clears risk data.
  void _handleEarthquakeChipTap(BuildContext context, WidgetRef ref) {
    final current = ref.read(selectedDisasterTypesProvider);
    final isCurrentlyChecking = ref.read(isCheckingRiskProvider);

    if (current.contains(DisasterType.earthquake)) {
      // Already selected → deselect and clear
      if (isCurrentlyChecking) return;
      final newSet = Set<DisasterType>.from(current)..remove(DisasterType.earthquake);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      ref.read(earthquakeRiskProvider.notifier).state = null;
    } else {
      // Not yet selected → select immediately and kick off the check
      final newSet = Set<DisasterType>.from(current)..add(DisasterType.earthquake);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      _checkEarthquakeRisk(context, ref);
    }
  }

  /// Dedicated handler for the Flood chip.
  void _handleFloodChipTap(BuildContext context, WidgetRef ref) {
    final current = ref.read(selectedDisasterTypesProvider);
    final isCurrentlyChecking = ref.read(isCheckingFloodRiskProvider);

    if (current.contains(DisasterType.flood)) {
      if (isCurrentlyChecking) return;
      final newSet = Set<DisasterType>.from(current)..remove(DisasterType.flood);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      ref.read(floodRiskProvider.notifier).state = null;
    } else {
      final newSet = Set<DisasterType>.from(current)..add(DisasterType.flood);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      _checkFloodRisk(context, ref);
    }
  }

  /// Fetch flood risk data for the user's current location.
  Future<void> _checkFloodRisk(BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
      return;
    }

    ref.read(isCheckingFloodRiskProvider.notifier).state = true;

    try {
      final disasterService = ref.read(disasterServiceProvider);
      final result = await disasterService.checkFloodRisk(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      ref.read(floodRiskProvider.notifier).state = result;

      if (result != null && context.mounted) {
        final isHigh = result.overallRisk == 'HIGH';
        final isMod = result.overallRisk == 'MODERATE';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHigh
                  ? '🚨 HIGH flood risk detected at your location!'
                  : isMod
                      ? '⚠️ Moderate flood risk detected'
                      : '✅ Flood risk is LOW at your location',
            ),
            backgroundColor: isHigh
                ? Colors.red.shade700
                : isMod
                    ? Colors.orange
                    : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking flood risk: $e')),
        );
      }
    } finally {
      ref.read(isCheckingFloodRiskProvider.notifier).state = false;
    }
  }

  /// Dedicated handler for the Weather chip.
  void _handleWeatherChipTap(BuildContext context, WidgetRef ref) {
    final current = ref.read(selectedDisasterTypesProvider);
    final isCurrentlyChecking = ref.read(isCheckingWeatherRiskProvider);

    if (current.contains(DisasterType.weather)) {
      if (isCurrentlyChecking) return;
      final newSet = Set<DisasterType>.from(current)..remove(DisasterType.weather);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      ref.read(weatherRiskProvider.notifier).state = null;
    } else {
      final newSet = Set<DisasterType>.from(current)..add(DisasterType.weather);
      ref.read(selectedDisasterTypesProvider.notifier).state = newSet;
      _checkWeatherRisk(context, ref);
    }
  }

  /// Fetch weather risk data for the user's current location.
  Future<void> _checkWeatherRisk(BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
      return;
    }

    ref.read(isCheckingWeatherRiskProvider.notifier).state = true;

    try {
      final disasterService = ref.read(disasterServiceProvider);
      final result = await disasterService.checkWeatherRisk(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      ref.read(weatherRiskProvider.notifier).state = result;

      if (result != null && context.mounted) {
        final risk = result.overallRisk;
        final isHigh = risk == 'HIGH';
        final isMod = risk == 'MODERATE';
        final isWindy = risk == 'WINDY';
        final isHeat = risk == 'HEAT';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHigh
                  ? '🚨 HIGH weather risk at your location!'
                  : isMod
                      ? '⚠️ Moderate weather conditions forecast'
                      : isWindy
                          ? '💨 Strong winds expected'
                          : isHeat
                              ? '🌡️ Heat conditions expected'
                              : '✅ Weather looks calm at your location',
            ),
            backgroundColor: isHigh
                ? Colors.red.shade700
                : isMod
                    ? Colors.orange
                    : isWindy || isHeat
                        ? Colors.amber.shade700
                        : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking weather risk: \$e')),
        );
      }
    } finally {
      ref.read(isCheckingWeatherRiskProvider.notifier).state = false;
    }
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
            color: bgColor.withValues(alpha: 0.4),
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.1),
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
              color: AppColors.danger.withValues(alpha: 0.1),
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

/// Panel showing earthquake risk results — collapsible so the map circles remain fully visible
class _EarthquakeRiskPanel extends StatelessWidget {
  final EarthquakeRiskResponse riskData;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onClose;
  final Function(EarthquakeRisk) onEarthquakeTap;

  const _EarthquakeRiskPanel({
    required this.riskData,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onClose,
    required this.onEarthquakeTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = riskData.threatDetected ? Colors.deepOrange : Colors.green;

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded ? const BoxConstraints(maxHeight: 260) : const BoxConstraints(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header — always visible, acts as the toggle handle
            GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: isExpanded ? Radius.zero : const Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      riskData.threatDetected
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            riskData.threatDetected
                                ? '⚠️ ${riskData.earthquakeCount} Earthquake(s) Detected'
                                : '✅ No Risk Identified',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Within 1000 km radius • Last 7 days',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand / collapse chevron
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    // Close button
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Collapsible content
            if (isExpanded) ...
              [
                if (riskData.earthquakes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          riskData.message.isNotEmpty
                              ? riskData.message
                              : 'No significant earthquakes (magnitude ≥ 4.0) detected within 1000 km in the last 7 days.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
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
          ],
        ),
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
                color: _getSeverityColor(earthquake.severity).withValues(alpha: 0.2),
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

// ─────────────────────────────────────────────
// Flood Risk Panel
// ─────────────────────────────────────────────

class _FloodRiskPanel extends StatelessWidget {
  final FloodRiskResponse riskData;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onClose;

  const _FloodRiskPanel({
    required this.riskData,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onClose,
  });

  Color get _headerColor {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return const Color(0xFFB71C1C);
      case 'MODERATE':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String get _headerIcon {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return '🚨';
      case 'MODERATE':
        return '⚠️';
      default:
        return '✅';
    }
  }

  String get _headerTitle {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return 'HIGH Flood Risk Detected';
      case 'MODERATE':
        return 'Moderate Flood Risk';
      default:
        return 'Flood Risk Is Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded
            ? const BoxConstraints(maxHeight: 320)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header (tap to collapse / expand) ──
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _headerColor,
                        _headerColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(18),
                      bottom: isExpanded
                          ? Radius.zero
                          : const Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_headerIcon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _headerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${riskData.daily.length}-day forecast  •  River discharge',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collapsible body ──
              if (isExpanded) ...[
                // Summary chips row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RiskSummaryChip(
                        label: '${riskData.lowCount} LOW',
                        color: const Color(0xFF43A047),
                        icon: '🟢',
                      ),
                      _RiskSummaryChip(
                        label: '${riskData.moderateCount} MOD',
                        color: const Color(0xFFF57C00),
                        icon: '🟠',
                      ),
                      _RiskSummaryChip(
                        label: '${riskData.highCount} HIGH',
                        color: const Color(0xFFE53935),
                        icon: '🔴',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF2A2A3E), thickness: 1),
                // Per-day scrollable timeline
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: riskData.daily.length,
                    itemBuilder: (context, index) =>
                        _FloodRiskDayTile(day: riskData.daily[index]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary chip ──
class _RiskSummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final String icon;

  const _RiskSummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$icon  $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Per-day tile ──
class _FloodRiskDayTile extends StatelessWidget {
  final FloodRiskDay day;

  const _FloodRiskDayTile({required this.day});

  Color get _riskColor {
    switch (day.risk) {
      case 'HIGH':
        return const Color(0xFFEF5350);
      case 'MODERATE':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  String get _riskEmoji {
    switch (day.risk) {
      case 'HIGH':
        return '🔴';
      case 'MODERATE':
        return '🟠';
      default:
        return '🟢';
    }
  }

  /// Clamp ratio 0–2 → 0–100% bar fill
  double get _barFraction => ((day.ratio ?? 0.0) / 2.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final discharge = day.riverDischarge;
    final dischargeStr =
        discharge != null ? '${discharge.toStringAsFixed(2)} m³/s' : '--';

    // Parse "2026-04-16" → "16 Apr"
    final parts = day.date.split('-');
    final dateLabel = parts.length == 3
        ? '${parts[2]} ${_monthAbbr(int.tryParse(parts[1]) ?? 1)}'
        : day.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: [
          // Date label
          SizedBox(
            width: 46,
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Discharge bar + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _barFraction,
                    minHeight: 7,
                    backgroundColor: const Color(0xFF2A2A3E),
                    valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dischargeStr,
                  style: const TextStyle(
                    color: Color(0xFF78909C),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Risk badge
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _riskColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              '$_riskEmoji ${day.risk}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _riskColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}

// ─────────────────────────────────────────────
// Weather Risk Panel
// ─────────────────────────────────────────────

class _WeatherRiskPanel extends StatelessWidget {
  final WeatherRiskResponse riskData;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onClose;

  const _WeatherRiskPanel({
    required this.riskData,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onClose,
  });

  Color get _headerColor {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return const Color(0xFF6A1B9A);
      case 'MODERATE':
        return const Color(0xFF1565C0);
      case 'WINDY':
        return const Color(0xFF00838F);
      case 'HEAT':
        return const Color(0xFFBF360C);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String get _headerEmoji {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return '🚨';
      case 'MODERATE':
        return '⚠️';
      case 'WINDY':
        return '💨';
      case 'HEAT':
        return '🌡️';
      default:
        return '✅';
    }
  }

  String get _headerTitle {
    switch (riskData.overallRisk) {
      case 'HIGH':
        return 'High Weather Risk';
      case 'MODERATE':
        return 'Moderate Weather Conditions';
      case 'WINDY':
        return 'Strong Winds Expected';
      case 'HEAT':
        return 'Heat Conditions Expected';
      default:
        return 'Weather Looks Calm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded
            ? const BoxConstraints(maxHeight: 340)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _headerColor,
                        _headerColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(18),
                      bottom: isExpanded ? Radius.zero : const Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_headerEmoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _headerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${riskData.daily.length}-day forecast  •  Tomorrow.io',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collapsible body ──
              if (isExpanded) ...[
                if (riskData.daily.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No forecast data available.\nCheck your Tomorrow.io API key.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: riskData.daily.length,
                      itemBuilder: (context, index) =>
                          _WeatherRiskDayTile(day: riskData.daily[index]),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Per-day weather tile ──
class _WeatherRiskDayTile extends StatelessWidget {
  final WeatherRiskDay day;

  const _WeatherRiskDayTile({required this.day});

  Color get _riskColor {
    switch (day.risk) {
      case 'HIGH':
        return const Color(0xFFEF5350);
      case 'MODERATE':
        return const Color(0xFF42A5F5);
      case 'WINDY':
        return const Color(0xFF26C6DA);
      case 'HEAT':
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  String get _riskEmoji {
    switch (day.risk) {
      case 'HIGH':
        return '🚨';
      case 'MODERATE':
        return '🌧️';
      case 'WINDY':
        return '💨';
      case 'HEAT':
        return '🌡️';
      default:
        return '☀️';
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final parts = day.date.split('-');
    final dateLabel = parts.length == 3
        ? '${parts[2]} ${_monthAbbr(int.tryParse(parts[1]) ?? 1)}'
        : day.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 46,
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Temp range
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.temperatureMax.toStringAsFixed(0)}° / ${day.temperatureMin.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Color(0xFFECEFF1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '💧${day.rainMm.toStringAsFixed(1)}mm  💨${day.windSpeedAvg.toStringAsFixed(0)}km/h',
                style: const TextStyle(
                  color: Color(0xFF78909C),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Risk badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _riskColor.withValues(alpha: 0.45), width: 1),
            ),
            child: Text(
              '$_riskEmoji ${day.risk}',
              style: TextStyle(
                color: _riskColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
