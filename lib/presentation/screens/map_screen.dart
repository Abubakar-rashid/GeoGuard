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

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 10.0;

  // ── Per-panel expand state (fixes overlap when both are open) ────────────
  bool _earthquakePanelExpanded = true;
  bool _floodPanelExpanded      = true;
  bool _weatherPanelExpanded    = true;

  @override
  void initState() {
    super.initState();
    // No automatic API calls on startup.
    // Earthquake / flood / weather checks are triggered only when the user
    // taps the corresponding chip in the left sidebar.
  }

  @override
  Widget build(BuildContext context) {
    final userLocation        = ref.watch(userLocationProvider);
    final disasters           = ref.watch(filteredDisastersProvider);
    final selectedTypes       = ref.watch(selectedDisasterTypesProvider);
    final earthquakeRisk      = ref.watch(earthquakeRiskProvider);
    final isCheckingRisk      = ref.watch(isCheckingRiskProvider);
    final floodRisk           = ref.watch(floodRiskProvider);
    final isCheckingFloodRisk = ref.watch(isCheckingFloodRiskProvider);
    final weatherRisk         = ref.watch(weatherRiskProvider);
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
          // ── Map ─────────────────────────────────────────────────────────
          userLocation.when(
            data: (location) {
              final center = location != null
                  ? LatLng(location.latitude, location.longitude)
                  : const LatLng(37.7749, -122.4194);

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
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoguard.app',
                    maxZoom: 19,
                    // Reduced buffers: loading 8/5 extra tiles was causing
                    // heavy network + render pressure. 2/1 is enough for
                    // smooth panning without excess tile fetching.
                    keepBuffer: 2,
                    panBuffer: 1,
                    tileProvider: CancellableNetworkTileProvider(),
                  ),

                  // ── Combined: filter disasters once, build both
                  //    CircleLayer and MarkerLayer from the same list.
                  //    Previously disasters.when() was called twice,
                  //    causing the list to be filtered/iterated twice
                  //    on every build.
                  disasters.when(
                    data: (disasterList) {
                      // Single filter pass for both layers.
                      final visible = disasterList.where((d) {
                        if (d.type == DisasterType.earthquake &&
                            earthquakeRisk != null) { return false; }
                        if (d.type == DisasterType.flood &&
                            floodRisk != null) { return false; }
                        if (d.type == DisasterType.weather &&
                            weatherRisk != null) { return false; }
                        return true;
                      }).toList();

                      return Stack(
                        children: [
                          CircleLayer(
                            circles: visible
                                .map((d) => CircleMarker(
                                      point: LatLng(
                                          d.latitude, d.longitude),
                                      radius: d.radiusKm * 1000,
                                      useRadiusInMeter: true,
                                      color: _getSeverityColor(
                                              d.severity)
                                          .withValues(alpha: 0.25),
                                      borderColor:
                                          _getSeverityColor(d.severity),
                                      borderStrokeWidth: 2,
                                    ))
                                .toList(),
                          ),
                          MarkerLayer(
                            markers: [
                              if (location != null)
                                Marker(
                                  point: LatLng(location.latitude,
                                      location.longitude),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ...visible.map((d) => Marker(
                                    point:
                                        LatLng(d.latitude, d.longitude),
                                    width: 40,
                                    height: 40,
                                    child:
                                        _DisasterMarkerIcon(disaster: d),
                                  )),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  // ── Earthquake risk circles (from USGS check) ───────
                  if (earthquakeRisk != null &&
                      earthquakeRisk.earthquakes.isNotEmpty)
                    CircleLayer(
                      circles: earthquakeRisk.earthquakes.map((eq) {
                        final radiusMetres = eq.magnitude * 15 * 1000;
                        return CircleMarker(
                          point: LatLng(eq.latitude, eq.longitude),
                          radius: radiusMetres,
                          useRadiusInMeter: true,
                          color: _getEarthquakeRiskColor(eq.severity)
                              .withValues(alpha: 0.22),
                          borderColor:
                              _getEarthquakeRiskColor(eq.severity),
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                const Center(child: Text('Error loading map')),
          ),

          // ── Your Location label ──────────────────────────────────────
          Positioned(
            top: 8,
            left: 8,
            child: RepaintBoundary(child: _YourLocationChip()),
          ),

          // ── Severity legend ──────────────────────────────────────────
          Positioned(
            top: 8,
            right: 12,
            child: RepaintBoundary(child: _MapLegend()),
          ),

          // ── Zoom controls ────────────────────────────────────────────
          Positioned(
            bottom: 110,
            right: 12,
            child: RepaintBoundary(
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onPressed: () {
                      final newZoom =
                          (_currentZoom + 1).clamp(3.0, 18.0);
                      _animatedMapMove(
                          _mapController.camera.center, newZoom);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onPressed: () {
                      final newZoom =
                          (_currentZoom - 1).clamp(3.0, 18.0);
                      _animatedMapMove(
                          _mapController.camera.center, newZoom);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Navigate to location ─────────────────────────────────────
          Positioned(
            bottom: 60,
            right: 12,
            child: RepaintBoundary(
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () {
                  final location =
                      ref.read(userLocationProvider).valueOrNull;
                  if (location != null) {
                    _animatedMapMove(
                      LatLng(location.latitude, location.longitude),
                      _currentZoom,
                    );
                  }
                },
                child: const Icon(Icons.navigation,
                    color: AppColors.primary),
              ),
            ),
          ),

          // ── Nearest Threat Card (only when no panels open) ────────────
          if (earthquakeRisk == null &&
              floodRisk == null &&
              weatherRisk == null)
            Positioned(
              bottom: 16,
              left: 6,
              right: 80,
              child: disasters.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return _NearestThreatCard(disaster: list.first);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),

          // ── Combined chip buttons + risk panels ────────────────────────
          Positioned(
            bottom: 16,
            left: 6,
            right: 12,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather row (top)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SidebarButton(
                        icon: Icons.cloud,
                        label: 'Weather',
                        color: AppColors.weather,
                        isSelected: selectedTypes.contains(DisasterType.weather),
                        isLoading: isCheckingWeatherRisk,
                        onTap: () => _handleWeatherChipTap(context, ref),
                      ),
                      if (weatherRisk != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _WeatherRiskPanel(
                            riskData: weatherRisk,
                            isExpanded: _weatherPanelExpanded,
                            onToggleExpand: () => setState(() =>
                                _weatherPanelExpanded = !_weatherPanelExpanded),
                            onClose: () {
                              ref.read(weatherRiskProvider.notifier).state = null;
                              final current = ref.read(selectedDisasterTypesProvider);
                              ref.read(selectedDisasterTypesProvider.notifier).state =
                                  Set<DisasterType>.from(current)..remove(DisasterType.weather);
                              setState(() => _weatherPanelExpanded = true);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Flood row (middle)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SidebarButton(
                        icon: Icons.water_drop,
                        label: 'Flood',
                        color: AppColors.flood,
                        isSelected: selectedTypes.contains(DisasterType.flood),
                        isLoading: isCheckingFloodRisk,
                        onTap: () => _handleFloodChipTap(context, ref),
                      ),
                      if (floodRisk != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FloodRiskPanel(
                            riskData: floodRisk,
                            isExpanded: _floodPanelExpanded,
                            onToggleExpand: () => setState(() =>
                                _floodPanelExpanded = !_floodPanelExpanded),
                            onClose: () {
                              ref.read(floodRiskProvider.notifier).state = null;
                              final current = ref.read(selectedDisasterTypesProvider);
                              ref.read(selectedDisasterTypesProvider.notifier).state =
                                  Set<DisasterType>.from(current)..remove(DisasterType.flood);
                              setState(() => _floodPanelExpanded = true);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Earthquake row (bottom)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SidebarButton(
                        icon: Icons.public,
                        label: 'Quake',
                        color: AppColors.earthquake,
                        isSelected: selectedTypes.contains(DisasterType.earthquake),
                        isLoading: isCheckingRisk,
                        onTap: () => _handleEarthquakeChipTap(context, ref),
                      ),
                      if (earthquakeRisk != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _EarthquakeRiskPanel(
                            riskData: earthquakeRisk,
                            isExpanded: _earthquakePanelExpanded,
                            onToggleExpand: () => setState(() =>
                                _earthquakePanelExpanded = !_earthquakePanelExpanded),
                            onClose: () {
                              ref.read(earthquakeRiskProvider.notifier).state = null;
                              final current = ref.read(selectedDisasterTypesProvider);
                              ref.read(selectedDisasterTypesProvider.notifier).state =
                                  Set<DisasterType>.from(current)..remove(DisasterType.earthquake);
                              setState(() => _earthquakePanelExpanded = true);
                            },
                            onEarthquakeTap: (eq) => _animatedMapMove(
                                LatLng(eq.latitude, eq.longitude), 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Risk check helpers ────────────────────────────────────────────────────

  Future<void> _checkEarthquakeRisk(
      BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      _showSnack(context, 'Unable to get your location');
      return;
    }
    ref.read(isCheckingRiskProvider.notifier).state = true;
    try {
      final result = await ref
          .read(disasterServiceProvider)
          .checkEarthquakeRisk(
            latitude: location.latitude,
            longitude: location.longitude,
            radiusKm: 1000,
            minMagnitude: 4.0,
            days: 7,
          );
      ref.read(earthquakeRiskProvider.notifier).state = result;
      if (result != null &&
          result.threatDetected &&
          result.earthquakes.isNotEmpty) {
        double minLat = location.latitude,
            maxLat = location.latitude;
        double minLon = location.longitude,
            maxLon = location.longitude;
        for (final eq in result.earthquakes) {
          minLat = min(minLat, eq.latitude);
          maxLat = max(maxLat, eq.latitude);
          minLon = min(minLon, eq.longitude);
          maxLon = max(maxLon, eq.longitude);
        }
        _animatedMapMove(
            LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2),
            5.0);
        if (context.mounted) {
          _showSnack(
            context,
            '⚠️ ${result.earthquakeCount} earthquake(s) detected within 1000 km!',
            color: Colors.deepOrange,
          );
        }
      } else {
        if (context.mounted) {
          _showSnack(
            context,
            '✅ No significant earthquake risk within 1000 km',
            color: Colors.green,
          );
        }
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Error: $e');
    } finally {
      ref.read(isCheckingRiskProvider.notifier).state = false;
    }
  }

  void _handleEarthquakeChipTap(BuildContext context, WidgetRef ref) {
    // Ignore if already in progress
    if (ref.read(isCheckingRiskProvider)) return;
    // Always mark selected and kick off a fresh check.
    // The X button on the panel is the dismiss action.
    final current = ref.read(selectedDisasterTypesProvider);
    ref.read(selectedDisasterTypesProvider.notifier).state =
        Set<DisasterType>.from(current)..add(DisasterType.earthquake);
    _checkEarthquakeRisk(context, ref);
  }

  Future<void> _checkFloodRisk(
      BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      _showSnack(context, 'Unable to get your location');
      return;
    }
    ref.read(isCheckingFloodRiskProvider.notifier).state = true;
    try {
      final result = await ref
          .read(disasterServiceProvider)
          .checkFloodRisk(
            latitude: location.latitude,
            longitude: location.longitude,
          );
      ref.read(floodRiskProvider.notifier).state = result;
      if (result != null && context.mounted) {
        final isHigh = result.overallRisk == 'HIGH';
        final isMod  = result.overallRisk == 'MODERATE';
        _showSnack(
          context,
          isHigh
              ? '🚨 HIGH flood risk detected!'
              : isMod
                  ? '⚠️ Moderate flood risk detected'
                  : '✅ Flood risk is LOW',
          color: isHigh
              ? Colors.red.shade700
              : isMod
                  ? Colors.orange
                  : Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Error: $e');
    } finally {
      ref.read(isCheckingFloodRiskProvider.notifier).state = false;
    }
  }

  void _handleFloodChipTap(BuildContext context, WidgetRef ref) {
    if (ref.read(isCheckingFloodRiskProvider)) return;
    final current = ref.read(selectedDisasterTypesProvider);
    ref.read(selectedDisasterTypesProvider.notifier).state =
        Set<DisasterType>.from(current)..add(DisasterType.flood);
    _checkFloodRisk(context, ref);
  }

  Future<void> _checkWeatherRisk(
      BuildContext context, WidgetRef ref) async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null) {
      _showSnack(context, 'Unable to get your location');
      return;
    }
    ref.read(isCheckingWeatherRiskProvider.notifier).state = true;
    try {
      final result = await ref
          .read(disasterServiceProvider)
          .checkWeatherRisk(
            latitude: location.latitude,
            longitude: location.longitude,
          );
      ref.read(weatherRiskProvider.notifier).state = result;
      if (result != null && context.mounted) {
        final risk    = result.overallRisk;
        final isHigh  = risk == 'HIGH';
        final isMod   = risk == 'MODERATE';
        final isWindy = risk == 'WINDY';
        final isHeat  = risk == 'HEAT';
        _showSnack(
          context,
          isHigh
              ? '🚨 HIGH weather risk!'
              : isMod
                  ? '⚠️ Moderate weather conditions forecast'
                  : isWindy
                      ? '💨 Strong winds expected'
                      : isHeat
                          ? '🌡️ Heat conditions expected'
                          : '✅ Weather looks calm',
          color: isHigh
              ? Colors.red.shade700
              : isMod
                  ? Colors.orange
                  : isWindy || isHeat
                      ? Colors.amber.shade700
                      : Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Error: $e');
    } finally {
      ref.read(isCheckingWeatherRiskProvider.notifier).state = false;
    }
  }

  void _handleWeatherChipTap(BuildContext context, WidgetRef ref) {
    if (ref.read(isCheckingWeatherRiskProvider)) return;
    final current = ref.read(selectedDisasterTypesProvider);
    ref.read(selectedDisasterTypesProvider.notifier).state =
        Set<DisasterType>.from(current)..add(DisasterType.weather);
    _checkWeatherRisk(context, ref);
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void _showSnack(BuildContext context, String msg,
      {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() => _mapController.move(
          LatLng(latTween.evaluate(animation),
              lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        ));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _currentZoom = destZoom;
        controller.dispose();
      }
    });
    controller.forward();
  }

  // ignore: unused_element
  double _calculateCircleRadius(double radiusKm) =>
      radiusKm * 1000 / (40075016.686 / (256 * (1 << _currentZoom.toInt())));

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.high:   return AppColors.severityHigh;
      case SeverityLevel.medium: return AppColors.severityMedium;
      case SeverityLevel.low:    return AppColors.severityLow;
    }
  }

  Color _getEarthquakeRiskColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':   return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':    return Colors.yellow.shade700;
      default:       return Colors.orange;
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


class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: color, width: 1.5)
              : Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textMuted,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAP OVERLAY WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Severity',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: AppColors.textPrimary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 7),
          _LegendItem(color: AppColors.severityHigh, label: 'High'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.severityMedium, label: 'Medium'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.severityLow, label: 'Low'),
        ],
      ),
    );
  }
}

class _YourLocationChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on,
              color: AppColors.danger, size: 14),
          const SizedBox(width: 4),
          Text(
            AppStrings.yourLocation,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISASTER MARKER
// ═══════════════════════════════════════════════════════════════════════════════

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
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 6,
            // No spreadRadius: reduces GPU compositing cost per marker.
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEGEND ITEM
// ═══════════════════════════════════════════════════════════════════════════════

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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ZOOM BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

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
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEAREST THREAT CARD
// ═══════════════════════════════════════════════════════════════════════════════

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
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              color: AppColors.danger.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning,
                color: AppColors.danger, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.nearestThreat,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
                Text(
                  '${disaster.distanceFromUser?.toStringAsFixed(0) ?? '--'} km • ${disaster.severity.name.toUpperCase()} Risk',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('View',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

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
          const Text('Filter Disasters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('More filter options coming soon...'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EARTHQUAKE RISK PANEL
// ═══════════════════════════════════════════════════════════════════════════════

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
    final headerColor =
        riskData.threatDetected ? AppColors.earthquake : AppColors.safe;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded
            ? const BoxConstraints(maxHeight: 240)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: headerColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: headerColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: isExpanded
                        ? Radius.zero
                        : const Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      riskData.threatDetected
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: Colors.white,
                      size: 18,
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
                                : '✅ No Earthquake Risk',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '1000 km radius • Last 7 days',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 10,
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
                      size: 20,
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            if (isExpanded)
              riskData.earthquakes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.safe, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            riskData.message.isNotEmpty
                                ? riskData.message
                                : 'No earthquakes (M≥4.0) within 1000 km in the last 7 days.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
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
      ),
    );
  }
}

class _EarthquakeListItem extends StatelessWidget {
  final EarthquakeRisk earthquake;
  final VoidCallback onTap;
  const _EarthquakeListItem(
      {required this.earthquake, required this.onTap});

  Color _severityColor() {
    switch (earthquake.severity.toLowerCase()) {
      case 'high':   return AppColors.severityHigh;
      case 'medium': return AppColors.severityMedium;
      default:       return AppColors.severityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = earthquake.dateTime;
    final timeStr = dt != null
        ? '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _severityColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: _severityColor(), width: 1.5),
              ),
              child: Center(
                child: Text(
                  earthquake.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _severityColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earthquake.place,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                  Text(
                    '${earthquake.distanceFromUser.toStringAsFixed(0)} km away',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOOD RISK PANEL
// ═══════════════════════════════════════════════════════════════════════════════

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
      case 'HIGH':     return AppColors.flood;
      case 'MODERATE': return const Color(0xFF2E7DB0);
      default:         return AppColors.safe;
    }
  }

  String get _headerTitle {
    switch (riskData.overallRisk) {
      case 'HIGH':     return '🚨 HIGH Flood Risk Detected';
      case 'MODERATE': return '⚠️ Moderate Flood Risk';
      default:         return '✅ Flood Risk Is Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded
            ? const BoxConstraints(maxHeight: 300)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _headerColor.withValues(alpha: 0.40), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _headerColor,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(16),
                      bottom: isExpanded
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _headerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${riskData.daily.length}-day forecast  •  River discharge',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 10,
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
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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
                const Divider(
                    height: 1, color: Color(0xFF2A2A3E), thickness: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
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

class _RiskSummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final String icon;
  const _RiskSummaryChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$icon  $label',
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11),
      ),
    );
  }
}

class _FloodRiskDayTile extends StatelessWidget {
  final FloodRiskDay day;
  const _FloodRiskDayTile({required this.day});

  Color get _riskColor {
    switch (day.risk) {
      case 'HIGH':     return const Color(0xFFEF5350);
      case 'MODERATE': return const Color(0xFFFF9800);
      default:         return const Color(0xFF66BB6A);
    }
  }

  String get _riskEmoji {
    switch (day.risk) {
      case 'HIGH':     return '🔴';
      case 'MODERATE': return '🟠';
      default:         return '🟢';
    }
  }

  double get _barFraction => ((day.ratio ?? 0.0) / 2.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final discharge = day.riverDischarge;
    final dischargeStr =
        discharge != null ? '${discharge.toStringAsFixed(2)} m³/s' : '--';
    final parts = day.date.split('-');
    final dateLabel = parts.length == 3
        ? '${parts[2]} ${_monthAbbr(int.tryParse(parts[1]) ?? 1)}'
        : day.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(dateLabel,
                style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _barFraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2A2A3E),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_riskColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(dischargeStr,
                    style: const TextStyle(
                        color: Color(0xFF78909C), fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(
                horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _riskColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              '$_riskEmoji ${day.risk}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _riskColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (month < 1 || month > 12) return '';
    return m[month - 1];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER RISK PANEL
// ═══════════════════════════════════════════════════════════════════════════════

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
      case 'HIGH':     return const Color(0xFF6A1B9A);
      case 'MODERATE': return const Color(0xFF1565C0);
      case 'WINDY':    return const Color(0xFF00838F);
      case 'HEAT':     return const Color(0xFFBF360C);
      default:         return AppColors.safe;
    }
  }

  String get _headerTitle {
    switch (riskData.overallRisk) {
      case 'HIGH':     return '🚨 High Weather Risk';
      case 'MODERATE': return '⚠️ Moderate Weather Conditions';
      case 'WINDY':    return '💨 Strong Winds Expected';
      case 'HEAT':     return '🌡️ Heat Conditions Expected';
      default:         return '✅ Weather Looks Calm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: isExpanded
            ? const BoxConstraints(maxHeight: 310)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _headerColor.withValues(alpha: 0.40), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _headerColor,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(16),
                      bottom: isExpanded
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _headerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${riskData.daily.length}-day forecast  •  Tomorrow.io',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 10,
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
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body
              if (isExpanded)
                riskData.daily.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'No forecast data available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFFB0BEC5), fontSize: 12),
                        ),
                      )
                    : Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          itemCount: riskData.daily.length,
                          itemBuilder: (context, index) =>
                              _WeatherRiskDayTile(
                                  day: riskData.daily[index]),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherRiskDayTile extends StatelessWidget {
  final WeatherRiskDay day;
  const _WeatherRiskDayTile({required this.day});

  Color get _riskColor {
    switch (day.risk) {
      case 'HIGH':     return const Color(0xFFEF5350);
      case 'MODERATE': return const Color(0xFF42A5F5);
      case 'WINDY':    return const Color(0xFF26C6DA);
      case 'HEAT':     return const Color(0xFFFF7043);
      default:         return const Color(0xFF66BB6A);
    }
  }

  String get _riskEmoji {
    switch (day.risk) {
      case 'HIGH':     return '🚨';
      case 'MODERATE': return '🌧️';
      case 'WINDY':    return '💨';
      case 'HEAT':     return '🌡️';
      default:         return '☀️';
    }
  }

  String _monthAbbr(int month) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (month < 1 || month > 12) return '';
    return m[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final parts = day.date.split('-');
    final dateLabel = parts.length == 3
        ? '${parts[2]} ${_monthAbbr(int.tryParse(parts[1]) ?? 1)}'
        : day.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(dateLabel,
                style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.temperatureMax.toStringAsFixed(0)}° / ${day.temperatureMin.toStringAsFixed(0)}°',
                style: const TextStyle(
                    color: Color(0xFFECEFF1),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '💧${day.rainMm.toStringAsFixed(1)}mm  💨${day.windSpeedAvg.toStringAsFixed(0)}km/h',
                style: const TextStyle(
                    color: Color(0xFF78909C), fontSize: 9),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _riskColor.withValues(alpha: 0.45), width: 1),
            ),
            child: Text(
              '$_riskEmoji ${day.risk}',
              style: TextStyle(
                  color: _riskColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
