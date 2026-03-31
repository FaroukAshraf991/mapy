import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/utils/map_icon_helper.dart';
import 'package:mapy/core/constants/app_constants.dart';

extension LatLngllExt on ll.LatLng {
  LatLng toLibre() => LatLng(latitude, longitude);
}

extension LatLngmlExt on LatLng {
  ll.LatLng toLl2() => ll.LatLng(latitude, longitude);
}

class MapLayerManager {
  final MapLibreMapController controller;
  bool _isIconsLoaded = false;
  bool _isUpdating = false;
  DateTime? _lastUpdateTime;

  MapLayerManager(this.controller);

  Future<void> updateLayers({
    required RouteInfo routeInfo,
    required LatLng? destinationLocation,
    required LatLng? currentLocation,
    required ll.LatLng? homeLocation,
    required ll.LatLng? workLocation,
    required List<Map<String, dynamic>> customPins,
    required bool isNavigating,
    required double navigationRotation,
    bool force = false,
    bool showTraffic = false,
  }) async {
    if (_isUpdating) return;

    final now = DateTime.now();
    if (!force &&
        _lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds <
            AppConstants.layerUpdateThrottleMs) {
      return;
    }

    _isUpdating = true;
    _lastUpdateTime = now;

    try {
      if (showTraffic) {
        await _addTrafficSource();
      } else {
        await _removeTrafficSource();
      }

      if (!_isIconsLoaded) {
        try {
          await MapIconHelper.addStandardIcons(controller);
          _isIconsLoaded = true;
        } catch (_) {
          _isIconsLoaded = true;
        }
      }

      await controller.clearSymbols();
      await controller.clearLines();
      await controller.clearCircles();

      if (routeInfo.hasRoute && routeInfo.points.isNotEmpty) {
        try {
          await controller.addLine(
            LineOptions(
              geometry: routeInfo.points.map((p) => p.toLibre()).toList(),
              lineColor: "#448AFF",
              lineWidth: 6.0,
              lineOpacity: 0.8,
              lineJoin: "round",
            ),
          );
        } on PlatformException catch (_) {}
      }

      if (destinationLocation != null) {
        try {
          await controller.addCircle(
            CircleOptions(
              geometry: destinationLocation,
              circleColor: "#FF5252",
              circleRadius: 8.0,
              circleStrokeWidth: 3.0,
              circleStrokeColor: "#FFFFFF",
            ),
          );

          await controller.addSymbol(
            SymbolOptions(
              geometry: destinationLocation,
              iconImage: "dest-pin",
              iconSize: 1.0,
              iconAnchor: "bottom",
            ),
          );
        } on PlatformException catch (_) {}
      }

      if (isNavigating && currentLocation != null) {
        try {
          await controller.addSymbol(
            SymbolOptions(
              geometry: currentLocation,
              iconImage: "user-arrow",
              iconSize: 0.8,
              iconRotate: navigationRotation,
            ),
          );
        } on PlatformException catch (_) {}
      }

      if (!isNavigating) {
        try {
          if (homeLocation != null) {
            await controller.addSymbol(
              SymbolOptions(
                geometry: homeLocation.toLibre(),
                iconImage: "home-pin",
                iconSize: 0.8,
              ),
            );
          }
          if (workLocation != null) {
            await controller.addSymbol(
              SymbolOptions(
                geometry: workLocation.toLibre(),
                iconImage: "work-pin",
                iconSize: 0.8,
              ),
            );
          }
          for (final pin in customPins) {
            await controller.addSymbol(
              SymbolOptions(
                geometry: LatLng(pin['lat'], pin['lon']),
                iconImage: "custom-pin",
                iconSize: 0.8,
              ),
            );
          }
        } on PlatformException catch (_) {}
      }
    } catch (e) {
      // Layer update error, ignore
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _addTrafficSource() async {
    try {
      await controller.addSource(
          'traffic',
          RasterSourceProperties(
            tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
            tileSize: 256,
          ));
      await controller.addLayer(
          'traffic',
          'traffic-layer',
          RasterLayerProperties(
            rasterOpacity: 0.3,
          ));
    } catch (e) {
      // Source may already exist, ignore
    }
  }

  Future<void> _removeTrafficSource() async {
    try {
      await controller.removeLayer('traffic-layer');
      await controller.removeSource('traffic');
    } catch (e) {
      // Source may not exist, ignore
    }
  }
}
