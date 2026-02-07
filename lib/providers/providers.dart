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

final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
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

final countrySearchProvider = 
    FutureProvider.family<List<String>, String>((ref, query) async {
  final disasterService = ref.watch(disasterServiceProvider);
  return disasterService.searchCountries(query: query);
});

final countryEdaProvider = 
    FutureProvider.family<CountryEDA?, String>((ref, countryName) async {
  final disasterService = ref.watch(disasterServiceProvider);
  return disasterService.getCountryEDA(countryName: countryName);
});

final selectedCountryProvider = StateProvider<String?>((ref) {
  return null;
});
