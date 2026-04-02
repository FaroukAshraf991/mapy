import 'dart:math' as math;
import 'package:latlong2/latlong.dart' as ll;

/// Helper class for route preview calculations.
class RoutePreviewHelper {
  /// Calculate bearing from current step to next point in HIGH-RESOLUTION polyline.
  /// This gives accurate bearing matching the actual road curve.
  static double calculateBearingFromPolyline(
    List<ll.LatLng> points,
    dynamic currentStep,
  ) {
    if (points.length < 2) return 0.0;

    // Find the closest point in polyline to current step location
    int closestIndex = 0;
    double minDistance = double.infinity;

    final stepLat = currentStep.location.latitude as double;
    final stepLon = currentStep.location.longitude as double;

    for (int i = 0; i < points.length; i++) {
      final dist = _haversineDistance(
        stepLat,
        stepLon,
        points[i].latitude,
        points[i].longitude,
      );

      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // Look exactly 1 point ahead in polyline
    final nextIndex = (closestIndex + 1).clamp(0, points.length - 1);

    // Calculate bearing from current point to next point
    final current = points[closestIndex];
    final next = points[nextIndex];

    final lat1 = current.latitude * math.pi / 180;
    final lat2 = next.latitude * math.pi / 180;
    final dLon = (next.longitude - current.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Calculate bearing between current step and next step.
  /// Returns 0.0 for the last step or if route has no steps.
  static double calculateStepBearing(
    List<dynamic> steps,
    int stepIndex,
  ) {
    if (steps.isEmpty || stepIndex >= steps.length - 1) return 0.0;

    final current = steps[stepIndex].location;
    final next = steps[stepIndex + 1].location;

    final lat1 = current.latitude * math.pi / 180;
    final lat2 = next.latitude * math.pi / 180;
    final dLon = (next.longitude - current.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Get the center point of the entire route for initial camera positioning.
  static ll.LatLng getRouteCenter(List<ll.LatLng> points) {
    if (points.isEmpty) return const ll.LatLng(0, 0);

    double sumLat = 0;
    double sumLon = 0;

    for (final point in points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }

    return ll.LatLng(sumLat / points.length, sumLon / points.length);
  }

  /// Calculate zoom level to fit route on screen.
  /// Returns a zoom level between 10 and 18.
  static double calculateFitZoom(List<ll.LatLng> points) {
    if (points.isEmpty) return 14.0;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;

    // Simple zoom calculation based on route span
    if (latDiff > 0.5 || lonDiff > 0.5) return 10.0;
    if (latDiff > 0.1 || lonDiff > 0.1) return 12.0;
    if (latDiff > 0.05 || lonDiff > 0.05) return 13.0;
    if (latDiff > 0.01 || lonDiff > 0.01) return 14.0;
    return 15.0;
  }

  /// Haversine formula to calculate distance between two coordinates in meters.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth radius in meters
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
