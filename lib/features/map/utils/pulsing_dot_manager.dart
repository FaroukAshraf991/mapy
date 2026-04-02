import 'dart:async';
import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';

class PulsingDotManager {
  final MapLibreMapController controller;
  Timer? _pulseTimer;
  bool _isPulsing = false;
  double _pulseValue = 1.0;
  bool _isRippleActive = false;

  PulsingDotManager(this.controller);

  void startPulsing() {
    if (_isPulsing) return;
    _isPulsing = true;
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updatePulse();
    });
  }

  void stopPulsing() {
    _isPulsing = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  void _updatePulse() {
    if (!_isPulsing) return;

    // Create a smooth sine wave pulse (1.0 → 0.3 → 1.0)
    final now = DateTime.now().millisecondsSinceEpoch;
    final progress = (now % 1500) / 1500.0; // 1.5 second cycle
    _pulseValue = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi));

    // Update the pulse circle layer
    _updatePulseLayer();

    // Create ripple rings every 0.5 seconds
    if (progress < 0.05 && !_isRippleActive) {
      _isRippleActive = true;
      _createRippleRing();
      Future.delayed(const Duration(milliseconds: 500), () {
        _isRippleActive = false;
      });
    }
  }

  Future<void> _updatePulseLayer() async {
    try {
      // Update the pulsing dot opacity
      await controller.setLayerProperties(
        'pulsing-dot',
        CircleLayerProperties(
          circleOpacity: _pulseValue,
          circleRadius: 8.0 + (_pulseValue - 0.3) * 5.0, // Pulse between 8-11.5
        ),
      );
    } catch (e) {
      // Layer might not exist yet, ignore
    }
  }

  Future<void> _createRippleRing() async {
    try {
      final ringId = 'ripple-${DateTime.now().millisecondsSinceEpoch}';

      // Add a new ripple ring
      await controller.addCircleLayer(
        'gps-location',
        ringId,
        CircleLayerProperties(
          circleRadius: 12.0,
          circleColor: '#4285F4',
          circleOpacity: 0.6,
          circleBlur: 0.5,
        ),
      );

      // Animate the ring expanding and fading
      _animateRippleRing(ringId);
    } catch (e) {
      // Ignore errors
    }
  }

  void _animateRippleRing(String ringId) async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        final opacity = 0.6 * (1.0 - i / 20.0);
        final radius = 12.0 + i * 2.0;
        await controller.setLayerProperties(
          ringId,
          CircleLayerProperties(
            circleRadius: radius,
            circleOpacity: opacity,
          ),
        );
      } catch (e) {
        break;
      }
    }

    // Remove the ring after animation
    try {
      await controller.removeLayer(ringId);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> updateDotPosition(LatLng position) async {
    try {
      // Update the pulsing dot source position
      await controller.setGeoJsonSource('gps-location', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            },
          },
        ],
      });
    } catch (e) {
      // Ignore
    }
  }

  Future<void> addPulsingDot(LatLng position) async {
    try {
      // Add the GPS location source
      await controller.addGeoJsonSource('gps-location', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            },
          },
        ],
      });

      // Add the outer glow layer (larger, semi-transparent)
      await controller.addCircleLayer(
        'gps-location',
        'pulsing-dot-glow',
        const CircleLayerProperties(
          circleRadius: 16.0,
          circleColor: '#4285F4',
          circleOpacity: 0.2,
          circleBlur: 1.0,
        ),
      );

      // Add the main pulsing dot layer
      await controller.addCircleLayer(
        'gps-location',
        'pulsing-dot',
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: '#4285F4',
          circleOpacity: 1.0,
          circleStrokeWidth: 2.0,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // Start the pulsing animation
      startPulsing();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> removePulsingDot() async {
    stopPulsing();
    try {
      await controller.removeLayer('pulsing-dot');
      await controller.removeLayer('pulsing-dot-glow');
      await controller.removeSource('gps-location');
    } catch (e) {
      // Ignore
    }
  }

  void dispose() {
    stopPulsing();
  }
}
