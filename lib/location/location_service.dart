import 'package:geolocator/geolocator.dart';

/// A location problem the user can understand (GPS off, permission denied...).
class LocationProblem implements Exception {
  final String message;
  final bool canOpenSettings;
  const LocationProblem(this.message, {this.canOpenSettings = false});

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();

  static Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationProblem(
          "Please turn on your phone's location (GPS).");
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationProblem(
        'Location permission is blocked. Please enable it in your phone settings.',
        canOpenSettings: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationProblem(
          'Location permission is needed for this feature.');
    }
  }

  /// One fresh GPS fix. Asks for permission first if needed.
  static Future<Position> currentPosition() async {
    await ensurePermission();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const LocationProblem(
          "Couldn't get your location. Please try again.");
    }
  }

  static Future<void> openSettings() => Geolocator.openAppSettings();
}
