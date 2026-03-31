import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_result.dart';
import '../features/map/models/route_info.dart';
import '../features/map/models/map_enums.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_response.dart';

/// Repository for map operations (geocoding and routing)
class MapRepository {
  final http.Client _httpClient;

  MapRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Search for places matching [query]. Returns up to 10 results.
  Future<ApiResponse<List<PlaceResult>>> searchPlaces(
    String query, {
    double? biasLat,
    double? biasLon,
    String? countryCodes,
  }) async {
    if (query.trim().isEmpty) {
      return ApiResponse.success([]);
    }

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
      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': AppConstants.nominatimUserAgent,
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return ApiResponse.error('Search failed',
            statusCode: response.statusCode);
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      final results = data
          .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Search failed: $e');
    }
  }

  /// Fetch a route between [origin] and [destination] for the given [mode].
  Future<ApiResponse<RouteInfo>> getRoute(
    LatLng origin,
    LatLng destination, {
    TravelMode mode = TravelMode.driving,
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
    });

    try {
      final response = await _httpClient.get(
        uri,
        headers: {'User-Agent': AppConstants.osrmUserAgent},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ApiResponse.success(RouteInfo.empty);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return ApiResponse.success(RouteInfo.empty);
      }

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

      return ApiResponse.success(RouteInfo(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        steps: steps,
      ));
    } catch (e) {
      return ApiResponse.success(RouteInfo.empty);
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
