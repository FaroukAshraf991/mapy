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
  bool _isPulsing = false;
  DateTime? _lastPulseTime;

  MapLayerManager(this.controller);

  Future<void> updateLayers({
    required RouteInfo routeInfo,
    required LatLng? destinationLocation,
    required LatLng? currentLocation,
    required LatLng? startLocation,
    required ll.LatLng? homeLocation,
    required ll.LatLng? workLocation,
    required List<Map<String, dynamic>> customPins,
    required bool isNavigating,
    required double navigationRotation,
    int routeProgressIndex = 0,
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

      // Draw route line — passed section (gray) + remaining section (blue)
      if (routeInfo.hasRoute && routeInfo.points.isNotEmpty) {
        final pts = routeInfo.points;
        final splitIdx = isNavigating
            ? routeProgressIndex.clamp(0, pts.length - 1)
            : 0;
        // Draw passed segment (gray, dimmed) when navigating and progress > 0
        if (isNavigating && splitIdx > 0) {
          try {
            await controller.addLine(
              LineOptions(
                geometry: pts.sublist(0, splitIdx + 1).map((p) => p.toLibre()).toList(),
                lineColor: "#888888",
                lineWidth: 5.0,
                lineOpacity: 0.45,
                lineJoin: "round",
              ),
            );
          } on PlatformException catch (_) {}
        }
        // Draw remaining segment (blue, full opacity)
        if (splitIdx < pts.length - 1) {
          try {
            await controller.addLine(
              LineOptions(
                geometry: pts.sublist(splitIdx).map((p) => p.toLibre()).toList(),
                lineColor: "#448AFF",
                lineWidth: 6.0,
                lineOpacity: 0.9,
                lineJoin: "round",
              ),
            );
          } on PlatformException catch (_) {}
        }
      }

      // Draw destination red pin
      if (destinationLocation != null && routeInfo.hasRoute) {
        try {
          // Red destination pin
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

      // Draw white start dot (like Google Maps)
      if (routeInfo.hasRoute && startLocation != null) {
        try {
          // White dot at start location
          await controller.addCircle(
            CircleOptions(
              geometry: startLocation,
              circleColor: "#FFFFFF",
              circleRadius: 12.0,
              circleStrokeWidth: 3.0,
              circleStrokeColor: "#4285F4",
            ),
          );
        } on PlatformException catch (_) {}
      }

      // Draw blue GPS dot or navigation arrow
      if (currentLocation != null) {
        if (isNavigating) {
          // Navigation arrow (replaces pulsing dot)
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
        } else {
          // Blue pulsing dot at GPS location
          try {
            await controller.addCircle(
              CircleOptions(
                geometry: currentLocation,
                circleColor: "#4285F4",
                circleRadius: 8.0,
                circleStrokeWidth: 2.0,
                circleStrokeColor: "#FFFFFF",
              ),
            );

            // Add outer glow for pulse effect
            await controller.addCircle(
              CircleOptions(
                geometry: currentLocation,
                circleColor: "#4285F4",
                circleRadius: 16.0,
                circleOpacity: 0.2,
                circleBlur: 1.0,
              ),
            );

            _isPulsing = true;
            _lastPulseTime = now;
          } on PlatformException catch (_) {}
        }
      }

      // Draw home/work/custom pins (only when not navigating)
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

  Future<void> updatePulseAnimation() async {
    if (!_isPulsing || _isUpdating) return;

    final now = DateTime.now();
    if (_lastPulseTime == null ||
        now.difference(_lastPulseTime!).inMilliseconds < 50) {
      return;
    }

    _lastPulseTime = now;

    // Pulse animation: scale from 8.0 to 12.0 and back
    final progress = (now.millisecondsSinceEpoch % 1500) / 1500.0;
    final pulseRadius = 8.0 + 4.0 * (0.5 + 0.5 * (progress * 2 - 1).abs());

    try {
      // Update the outer glow circle for pulse effect
      await controller.setLayerProperties(
        'pulsing-dot-glow',
        CircleLayerProperties(
          circleRadius: pulseRadius,
          circleOpacity: 0.3 - 0.1 * progress,
        ),
      );
    } catch (e) {
      // Layer might not exist yet
    }
  }

  void stopPulsing() {
    _isPulsing = false;
  }

  Future<void> animateRouteDraw(List<ll.LatLng> points) async {
    if (points.isEmpty) return;

    try {
      // Clear existing route
      await controller.clearLines();

      // Draw route progressively
      final totalPoints = points.length;
      const pointsPerFrame = 5;
      final frames = (totalPoints / pointsPerFrame).ceil();

      for (int frame = 0; frame < frames; frame++) {
        final endIdx = ((frame + 1) * pointsPerFrame).clamp(0, totalPoints);
        final segmentPoints = points.sublist(0, endIdx);

        await controller.addLine(
          LineOptions(
            geometry: segmentPoints.map((p) => p.toLibre()).toList(),
            lineColor: "#448AFF",
            lineWidth: 6.0,
            lineOpacity: 0.8,
            lineJoin: "round",
          ),
        );

        await Future.delayed(const Duration(milliseconds: 16));

        if (frame < frames - 1) {
          await controller.clearLines();
        }
      }
    } catch (e) {
      // Ignore animation errors
    }
  }

  Future<void> animateRouteSwap(List<ll.LatLng> newPoints) async {
    if (newPoints.isEmpty) return;

    try {
      // Fade out existing route
      for (double opacity = 0.8; opacity > 0; opacity -= 0.2) {
        await controller.setLayerProperties(
          'route-line',
          LineLayerProperties(lineOpacity: opacity),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Clear and draw new route
      await controller.clearLines();
      await animateRouteDraw(newPoints);
    } catch (e) {
      // Fallback to direct draw
      await controller.clearLines();
      await controller.addLine(
        LineOptions(
          geometry: newPoints.map((p) => p.toLibre()).toList(),
          lineColor: "#448AFF",
          lineWidth: 6.0,
          lineOpacity: 0.8,
          lineJoin: "round",
        ),
      );
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
