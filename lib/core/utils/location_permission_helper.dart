import 'package:geolocator/geolocator.dart';

/// Result of a location permission request.
class LocationPermissionResult {
  final bool granted;
  final String? errorMessage;

  const LocationPermissionResult({required this.granted, this.errorMessage});
}

/// Utility for handling location permission requests.
class LocationPermissionHelper {
  /// Requests location permission from the user.
  /// Returns a result indicating success or failure with an error message.
  static Future<LocationPermissionResult> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationPermissionResult(
        granted: false,
        errorMessage: 'Location services are disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationPermissionResult(
          granted: false,
          errorMessage: 'Location permissions are denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionResult(
        granted: false,
        errorMessage: 'Location permissions are permanently denied.',
      );
    }

    return const LocationPermissionResult(granted: true);
  }
}
