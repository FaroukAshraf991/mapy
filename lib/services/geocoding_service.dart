import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapy/models/place_result.dart';

/// Geocoding and routing service using free, key-less OSM APIs:
/// - Nominatim for place search
/// - OSRM for road-following route geometry + ETA/distance
class GeocodingService {
  // ── Nominatim ─────────────────────────────────────────────────────────────
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  /// Search for places matching [query]. Returns up to 8 results.
  static Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '8',
      'addressdetails': '0',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MapyApp/1.0 (contact@mapy.app)',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── OSRM ──────────────────────────────────────────────────────────────────
  static const String _osrmBase = 'https://router.project-osrm.org';

  /// Fetch a driving route between [origin] and [destination].
  /// Returns a [RouteInfo] with road waypoints, distance, and ETA.
  static Future<RouteInfo> getRoute(
      LatLng origin, LatLng destination) async {
    final coordStr =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

    final uri = Uri.parse('$_osrmBase/route/v1/driving/$coordStr')
        .replace(queryParameters: {
      'overview': 'full',
      'geometries': 'geojson',
    });

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MapyApp/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return RouteInfo.empty;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return RouteInfo.empty;

      final route = routes.first as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).toDouble();

      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final points = coordinates.map((c) {
        final pair = c as List<dynamic>;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      return RouteInfo(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      return RouteInfo.empty;
    }
  }
}
