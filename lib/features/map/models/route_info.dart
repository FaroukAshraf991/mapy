import 'package:flutter/material.dart';
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

  /// Navigation instructions for this route.
  final List<RouteStep> steps;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
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

/// Represents a single maneuver in a route (e.g., "Turn left onto High St").
class RouteStep {
  final String instruction;
  final String maneuverType; // e.g., 'turn', 'depart', 'arrive'
  final String modifier; // e.g., 'left', 'right', 'straight'
  final String name; // Road name
  final LatLng location; // Coordinate of the maneuver

  const RouteStep({
    required this.instruction,
    required this.maneuverType,
    required this.location,
    this.modifier = '',
    this.name = '',
  });

  /// Map OSRM modifiers to Material icons.
  IconData get icon {
    if (maneuverType == 'arrive') return Icons.location_on_rounded;
    if (maneuverType == 'depart') return Icons.my_location_rounded;
    
    switch (modifier) {
      case 'left':
      case 'slight left':
      case 'sharp left':
        return Icons.turn_left_rounded;
      case 'right':
      case 'slight right':
      case 'sharp right':
        return Icons.turn_right_rounded;
      case 'u-turn':
        return Icons.u_turn_right_rounded;
      case 'straight':
        return Icons.straight_rounded;
      default:
        return Icons.navigation_rounded;
    }
  }
}
