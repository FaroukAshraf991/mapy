import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/features/map/models/route_info.dart';

/// Travel modes supported by the OSRM routing service.
enum TravelMode { driving, foot, bicycle, motorcycle }

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

  /// Fetch a route between [origin] and [destination] for the given [mode].
  /// Returns a [RouteInfo] with road waypoints, distance, and ETA.
  static Future<RouteInfo> getRoute(
      LatLng origin, LatLng destination, {TravelMode mode = TravelMode.driving}) async {
    final coordStr =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

    // OpenStreetMap.de provides separate endpoints for different profiles
    String baseUrl;
    switch (mode) {
      case TravelMode.foot:
        baseUrl = 'https://routing.openstreetmap.de/routed-foot';
        break;
      case TravelMode.bicycle:
        baseUrl = 'https://routing.openstreetmap.de/routed-bike';
        break;
      case TravelMode.motorcycle:
      case TravelMode.driving:
        baseUrl = 'https://routing.openstreetmap.de/routed-car';
        break;
    }

    final uri = Uri.parse('$baseUrl/route/v1/driving/$coordStr')
        .replace(queryParameters: {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'true', // Get turn-by-turn instructions
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

      // PARSE STEPS
      List<RouteStep> steps = [];
      final legs = route['legs'] as List<dynamic>?;
      if (legs != null && legs.isNotEmpty) {
        final legSteps = legs.first['steps'] as List<dynamic>?;
        if (legSteps != null) {
          steps = legSteps.map((s) {
            final maneuver = s['maneuver'] as Map<String, dynamic>;
            final maneuverLoc = maneuver['location'] as List<dynamic>;
            return RouteStep(
              instruction: maneuver['instruction'] as String? ?? 'Keep straight',
              maneuverType: maneuver['type'] as String? ?? 'turn',
              location: LatLng(
                (maneuverLoc[1] as num).toDouble(),
                (maneuverLoc[0] as num).toDouble(),
              ),
              modifier: maneuver['modifier'] as String? ?? '',
              name: s['name'] as String? ?? '',
            );
          }).toList();
        }
      }

      return RouteInfo(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        steps: steps,
      );
    } catch (_) {
      return RouteInfo.empty;
    }
  }
}
