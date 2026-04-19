import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/services.dart';
import '../data/models/models.dart';

// ============ API CLIENT ============

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ============ SERVICES ============

final disasterServiceProvider = Provider<DisasterService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DisasterService(apiClient: apiClient);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final aiAssistantServiceProvider = Provider<AIAssistantService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIAssistantService(apiClient: apiClient);
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

// ============ LOCATION ============

final userLocationProvider = FutureProvider<UserLocation?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocation();
});

final locationStreamProvider = StreamProvider<UserLocation>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getLocationStream();
});

// ============ DISASTERS ============

final earthquakesProvider = FutureProvider<List<Disaster>>((ref) async {
  final disasterService = ref.watch(disasterServiceProvider);
  final location = await ref.watch(userLocationProvider.future);

  if (location != null) {
    return disasterService.getEarthquakesNearLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      radiusKm: 500,
    );
  }

  return disasterService.getEarthquakes();
});

final allDisastersProvider = FutureProvider<List<Disaster>>((ref) async {
  final disasterService = ref.watch(disasterServiceProvider);
  final location = await ref.watch(userLocationProvider.future);

  return disasterService.getAllDisasters(
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
});

final riskAnalyticsInsightProvider = FutureProvider<String>((ref) async {
  final disasters = await ref.watch(allDisastersProvider.future);

  if (disasters.isEmpty) {
    return 'No active hazard feed is available yet. Once disaster data loads, this section will summarize the current risk pattern.';
  }

  final earthquakeCount = disasters
      .where((d) => d.type == DisasterType.earthquake)
      .length;
  final floodCount = disasters
      .where((d) => d.type == DisasterType.flood)
      .length;
  final weatherCount = disasters
      .where((d) => d.type == DisasterType.weather)
      .length;
  final highCount = disasters
      .where((d) => d.severity == SeverityLevel.high)
      .length;
  final mediumCount = disasters
      .where((d) => d.severity == SeverityLevel.medium)
      .length;
  final lowCount = disasters
      .where((d) => d.severity == SeverityLevel.low)
      .length;

  final total = disasters.length;
  final dominantHazard = {
    'Earthquakes': earthquakeCount,
    'Floods': floodCount,
    'Weather alerts': weatherCount,
  }..removeWhere((_, value) => value == 0);

  final sortedDominant = dominantHazard.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));

  final topHazard = sortedDominant.isNotEmpty
      ? sortedDominant.first.key
      : 'mixed hazards';
  final highShare = (highCount / total * 100).round();
  final mediumShare = (mediumCount / total * 100).round();
  final lowShare = (lowCount / total * 100).round();

  final now = DateTime.now();
  final lastThreeDays = disasters
      .where((d) => now.difference(d.timestamp).inDays <= 2)
      .length;
  final priorFourDays = disasters.where((d) {
    final age = now.difference(d.timestamp).inDays;
    return age >= 3 && age <= 6;
  }).length;

  final trendDescription = lastThreeDays > priorFourDays
      ? 'activity is rising'
      : lastThreeDays < priorFourDays
      ? 'activity is easing'
      : 'activity is steady';

  final prompt = StringBuffer()
    ..writeln(
      'You are summarizing a disaster analytics dashboard for a safety app.',
    )
    ..writeln('Write 3 concise bullets and 1 practical action line.')
    ..writeln('Use calm, direct language. Avoid jargon.')
    ..writeln('Data:')
    ..writeln('- total events: $total')
    ..writeln('- earthquakes: $earthquakeCount')
    ..writeln('- floods: $floodCount')
    ..writeln('- weather alerts: $weatherCount')
    ..writeln(
      '- severity high/medium/low: $highShare/$mediumShare/$lowShare percent',
    )
    ..writeln('- last 3 days events: $lastThreeDays')
    ..writeln('- previous 4 days events: $priorFourDays')
    ..writeln('- trend: $trendDescription')
    ..writeln('- dominant hazard: $topHazard');

  final aiAssistant = ref.watch(aiAssistantServiceProvider);
  return aiAssistant.chat(prompt.toString());
});

// ============ SAFETY STATUS ============

final safetyStateProvider = FutureProvider<SafetyState>((ref) async {
  final disasters = await ref.watch(allDisastersProvider.future);
  final location = await ref.watch(userLocationProvider.future);
  final locationService = ref.watch(locationServiceProvider);

  if (location == null || disasters.isEmpty) {
    return SafetyState.safe();
  }

  // Calculate distance to each disaster and find the nearest
  Disaster? nearestDisaster;
  double nearestDistance = double.infinity;

  for (final disaster in disasters) {
    final distance = locationService.calculateDistance(
      location.latitude,
      location.longitude,
      disaster.latitude,
      disaster.longitude,
    );

    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearestDisaster = disaster;
    }
  }

  if (nearestDisaster == null) {
    return SafetyState.safe();
  }

  // Determine safety status based on distance and severity
  if (nearestDistance <= nearestDisaster.radiusKm) {
    return SafetyState.danger(
      nearestThreat: nearestDisaster,
      distance: nearestDistance,
    );
  } else if (nearestDistance <= nearestDisaster.radiusKm * 2) {
    return SafetyState.warning(
      nearestThreat: nearestDisaster,
      distance: nearestDistance,
    );
  }

  return SafetyState(
    status: SafetyStatus.safe,
    message: 'No immediate threats detected',
    nearestThreat: nearestDisaster,
    distanceToNearestThreat: nearestDistance,
  );
});

// ============ DISASTER FILTERS ============

final selectedDisasterTypesProvider = StateProvider<Set<DisasterType>>((ref) {
  return {DisasterType.earthquake, DisasterType.flood, DisasterType.weather};
});

final filteredDisastersProvider = FutureProvider<List<Disaster>>((ref) async {
  final allDisasters = await ref.watch(allDisastersProvider.future);
  final selectedTypes = ref.watch(selectedDisasterTypesProvider);

  return allDisasters.where((d) => selectedTypes.contains(d.type)).toList();
});

// ============ EMERGENCY CONTACTS ============

final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((
  ref,
) async {
  final storage = ref.watch(localStorageServiceProvider);
  return storage.getEmergencyContacts();
});

// ============ SETTINGS ============

final darkModeProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return storage.getDarkModeEnabled();
});

final pushNotificationsProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return storage.getPushNotificationsEnabled();
});

final locationTrackingProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return storage.getLocationTrackingEnabled();
});

// ============ COUNTRY EDA ============

final countrySearchProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  final disasterService = ref.watch(disasterServiceProvider);
  return disasterService.searchCountries(query: query);
});

final countryEdaProvider = FutureProvider.family<CountryEDA?, String>((
  ref,
  countryName,
) async {
  final disasterService = ref.watch(disasterServiceProvider);
  return disasterService.getCountryEDA(countryName: countryName);
});

final selectedCountryProvider = StateProvider<String?>((ref) {
  return null;
});

// ============ EARTHQUAKE RISK ============

/// Provider for earthquake risk data - triggered manually
final earthquakeRiskProvider = StateProvider<EarthquakeRiskResponse?>((ref) {
  return null;
});

/// Provider to track if earthquake risk check is loading
final isCheckingRiskProvider = StateProvider<bool>((ref) {
  return false;
});

// ============ FLOOD RISK ============

/// Provider for flood risk data - triggered manually when the Flood chip is tapped
final floodRiskProvider = StateProvider<FloodRiskResponse?>((ref) {
  return null;
});

/// Provider to track if flood risk check is loading
final isCheckingFloodRiskProvider = StateProvider<bool>((ref) {
  return false;
});

// ============ WEATHER RISK ============

/// Provider for weather risk data - triggered manually when the Weather chip is tapped
final weatherRiskProvider = StateProvider<WeatherRiskResponse?>((ref) {
  return null;
});

/// Provider to track if weather risk check is loading
final isCheckingWeatherRiskProvider = StateProvider<bool>((ref) {
  return false;
});
