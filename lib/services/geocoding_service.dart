import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/core/constants/app_constants.dart';

/// Geocoding and routing service using free, key-less OSM APIs.
class GeocodingService {
  /// Search for places matching [query]. Returns up to 8 results.
  static Future<List<PlaceResult>> searchPlaces(
    String query, {
    double? biasLat,
    double? biasLon,
    String? countryCodes,
  }) async {
    if (query.trim().isEmpty) return [];

    final Map<String, String> queryParams = {
      'q': query,
      'format': 'json',
      'limit': '10',
      'addressdetails': '1',
    };

    if (biasLat != null && biasLon != null) {
      queryParams['lat'] = biasLat.toString();
      queryParams['lon'] = biasLon.toString();
      final minLat = biasLat - 0.5;
      final maxLat = biasLat + 0.5;
      final minLon = biasLon - 0.5;
      final maxLon = biasLon + 0.5;
      queryParams['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
    }

    if (countryCodes != null) {
      queryParams['countrycodes'] = countryCodes;
    }

    final uri = Uri.parse('${AppConstants.nominatimBaseUrl}/search')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': AppConstants.nominatimUserAgent,
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

  /// Fetch a route between [origin] and [destination] for the given [mode].
  static Future<RouteInfo> getRoute(LatLng origin, LatLng destination,
      {TravelMode mode = TravelMode.driving}) async {
    final routes = await getRouteAlternatives(origin, destination, mode: mode);
    return routes.isNotEmpty ? routes.first.routeInfo : RouteInfo.empty;
  }

  /// Fetch multiple route alternatives between [origin] and [destination].
  static Future<List<RouteAlternative>> getRouteAlternatives(
    LatLng origin,
    LatLng destination, {
    TravelMode mode = TravelMode.driving,
    int alternatives = 3,
  }) async {
    final coordStr =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

    String baseUrl;
    switch (mode) {
      case TravelMode.foot:
        baseUrl = AppConstants.osrmFootUrl;
        break;
      case TravelMode.bicycle:
        baseUrl = AppConstants.osrmBikeUrl;
        break;
      case TravelMode.motorcycle:
      case TravelMode.driving:
        baseUrl = AppConstants.osrmCarUrl;
        break;
    }

    final uri = Uri.parse('$baseUrl/route/v1/driving/$coordStr')
        .replace(queryParameters: {
      'overview': 'simplified',
      'geometries': 'geojson',
      'steps': 'true',
      'alternatives': alternatives.toString(),
    });

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': AppConstants.osrmUserAgent},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      return routes.asMap().entries.map((entry) {
        final idx = entry.key;
        final route = entry.value as Map<String, dynamic>;
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

        List<RouteStep> steps = [];
        final legs = route['legs'] as List<dynamic>?;
        if (legs != null && legs.isNotEmpty) {
          final legSteps = legs.first['steps'] as List<dynamic>?;
          if (legSteps != null) {
            steps = legSteps.map((s) {
              final maneuver = s['maneuver'] as Map<String, dynamic>;
              final maneuverLoc = maneuver['location'] as List<dynamic>;
              return RouteStep(
                instruction:
                    maneuver['instruction'] as String? ?? 'Keep straight',
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

        String routeName;
        if (idx == 0) {
          routeName = 'Fastest Route';
        } else if (idx == 1) {
          routeName = 'Alternative';
        } else {
          routeName = 'Route ${idx + 1}';
        }

        return RouteAlternative(
          id: idx,
          name: routeName,
          routeInfo: RouteInfo(
            points: points,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            steps: steps,
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
