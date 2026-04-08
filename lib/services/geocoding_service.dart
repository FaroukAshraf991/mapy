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
      'dedupe': '1',
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

  /// Reverse-geocodes [lat]/[lon] and returns the ISO 3166-1 alpha-2 country
  /// code (e.g. "eg", "us") or null if it cannot be determined.
  static Future<String?> getCountryCode(double lat, double lon) async {
    final uri = Uri.parse('${AppConstants.nominatimBaseUrl}/reverse').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
        'zoom': '3',
      },
    );
    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': AppConstants.nominatimUserAgent,
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      return address?['country_code'] as String?;
    } catch (_) {
      return null;
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
      'overview': 'full',
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
              final type = maneuver['type'] as String? ?? 'turn';
              final modifier = maneuver['modifier'] as String? ?? '';
              final streetName = s['name'] as String? ?? '';
              final exitNumber = maneuver['exit'] as int?;
              return RouteStep(
                instruction: _buildInstruction(type, modifier, streetName, exitNumber),
                maneuverType: type,
                location: LatLng(
                  (maneuverLoc[1] as num).toDouble(),
                  (maneuverLoc[0] as num).toDouble(),
                ),
                modifier: modifier,
                name: streetName,
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

  /// Generates a human-readable instruction from OSRM maneuver fields.
  /// OSRM never returns an `instruction` string — it only gives type + modifier.
  static String _buildInstruction(
      String type, String modifier, String name, int? exit) {
    final on = name.isNotEmpty ? ' on $name' : '';
    final mod = modifier.isNotEmpty ? modifier : 'straight';

    switch (type) {
      case 'depart':
        return 'Head ${_modifierToDirection(modifier)}${on.isNotEmpty ? on : ''}';
      case 'arrive':
        return 'You have arrived at your destination';
      case 'turn':
        if (modifier == 'straight') return 'Continue straight${on}';
        if (modifier == 'uturn') return 'Make a U-turn${on}';
        return 'Turn ${_capitalize(modifier)}${on}';
      case 'continue':
      case 'new name':
        if (modifier == 'straight' || modifier.isEmpty) return 'Continue straight${on}';
        return 'Continue ${_capitalize(modifier)}${on}';
      case 'merge':
        return 'Merge ${_capitalize(mod)}${on}';
      case 'on ramp':
        return 'Take the ramp on the ${_capitalize(mod)}${on}';
      case 'off ramp':
        return 'Take the exit on the ${_capitalize(mod)}${on}';
      case 'fork':
        return 'Keep ${_capitalize(mod)} at the fork${on}';
      case 'end of road':
        return 'Turn ${_capitalize(mod)} at the end of the road${on}';
      case 'roundabout':
      case 'rotary':
        if (exit != null) {
          return 'Take the ${_ordinal(exit)} exit at the roundabout${on}';
        }
        return 'Enter the roundabout${on}';
      case 'roundabout turn':
        return 'At the roundabout, turn ${_capitalize(mod)}${on}';
      case 'exit roundabout':
      case 'exit rotary':
        return 'Exit the roundabout${on}';
      case 'use lane':
        return 'Use the correct lane${on}';
      case 'notification':
        return 'Continue${on}';
      default:
        if (modifier == 'straight' || modifier.isEmpty) return 'Continue straight${on}';
        return '${_capitalize(type)} ${_capitalize(mod)}${on}';
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  static String _modifierToDirection(String modifier) {
    switch (modifier) {
      case 'north': return 'north';
      case 'south': return 'south';
      case 'east': return 'east';
      case 'west': return 'west';
      case 'right': return 'east';
      case 'left': return 'west';
      default: return 'forward';
    }
  }
}
