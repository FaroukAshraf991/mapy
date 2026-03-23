import 'package:latlong2/latlong.dart';

/// Distance + ETA data returned alongside a route polyline from OSRM.
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  static const RouteInfo empty =
      RouteInfo(points: [], distanceMeters: 0, durationSeconds: 0);

  bool get hasRoute => points.isNotEmpty;

  /// e.g. "12.3 km" or "850 m"
  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// e.g. "~5 min" or "~1 h 12 min"
  String get etaText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '~$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }
}

/// Represents a single geocoding result returned from Nominatim.
class PlaceResult {
  final String displayName;
  final double lat;
  final double lon;

  const PlaceResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] as String,
      lat: json['lat'] is String
          ? double.parse(json['lat'] as String)
          : (json['lat'] as num).toDouble(),
      lon: json['lon'] is String
          ? double.parse(json['lon'] as String)
          : (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'lat': lat,
        'lon': lon,
      };

  /// Short label: the first segment of display_name (usually the place name).
  String get shortName => displayName.split(',').first.trim();

  /// Subtitle: the rest of the address after the first segment.
  String get address {
    final parts = displayName.split(',');
    return parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  }
}
