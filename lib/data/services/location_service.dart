import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user location
  Future<UserLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Get direction from one point to another
  String getDirection(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    final bearing = Geolocator.bearingBetween(fromLat, fromLon, toLat, toLon);
    return _bearingToDirection(bearing);
  }

  String _bearingToDirection(double bearing) {
    if (bearing < 0) bearing += 360;

    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SW';
    if (bearing >= 247.5 && bearing < 292.5) return 'W';
    return 'NW';
  }

  /// Stream location updates
  Stream<UserLocation> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => UserLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now(),
            ));
  }

  /// Check if user is within danger zone
  bool isWithinDangerZone(
    double userLat,
    double userLon,
    double disasterLat,
    double disasterLon,
    double dangerRadiusKm,
  ) {
    final distance = calculateDistance(userLat, userLon, disasterLat, disasterLon);
    return distance <= dangerRadiusKm;
  }
}
