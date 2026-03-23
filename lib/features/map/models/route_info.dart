import 'package:latlong2/latlong.dart';

/// Holds the result of an OSRM routing call:
/// road waypoints + distance + estimated driving time.
class RouteInfo {
  /// Ordered list of [LatLng] points forming the road-following polyline.
  final List<LatLng> points;

  /// Total route distance in metres.
  final double distanceMeters;

  /// Estimated driving duration in seconds.
  final double durationSeconds;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Represents an empty / no-route state.
  static const RouteInfo empty =
      RouteInfo(points: [], distanceMeters: 0, durationSeconds: 0);

  /// Whether this object contains a real route.
  bool get hasRoute => points.isNotEmpty;

  // ── Display helpers ───────────────────────────────────────────────────────

  /// Human-readable distance, e.g. `"12.3 km"` or `"850 m"`.
  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Human-readable ETA, e.g. `"~18 min"` or `"~1 h 5 min"`.
  String get etaText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '~$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }
}
