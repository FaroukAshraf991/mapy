import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/utils/route_preview_helper.dart';

/// Route Preview Screen - Static step-through preview of route.
class RoutePreviewScreen extends StatefulWidget {
  final RouteInfo routeInfo;
  final String originName;
  final String destinationName;

  const RoutePreviewScreen({
    super.key,
    required this.routeInfo,
    required this.originName,
    required this.destinationName,
  });

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  int _currentIndex = 0;
  MapLibreMapController? _mapController;
  bool _isIconLoaded = false;
  bool _isAnimating = false;

  /// Current step driven by _currentIndex
  RouteStep get _currentStep => widget.routeInfo.steps[_currentIndex];

  /// Get current instruction text - REACTIVE to _currentIndex
  String get _currentInstruction => _currentStep.instruction;

  /// Get current step icon - REACTIVE to _currentIndex
  IconData get _currentIcon => _currentStep.icon;

  /// Get bearing for current step
  double get _currentBearing => RoutePreviewHelper.calculateStepBearing(
      widget.routeInfo.steps, _currentIndex);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // MapLibre Map with FULL polyline geometry
          _buildMap(isDark),

          // Floating Card at Top
          Positioned(
            top: MediaQuery.of(context).padding.top + context.h(50),
            left: context.w(16),
            right: context.w(16),
            child: _buildFloatingCard(isDark),
          ),

          // Step Navigation Chevrons
          if (widget.routeInfo.steps.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: _buildStepNav(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    // Get initial position from first step
    LatLng initialTarget;
    double initialBearing = 0.0;

    if (widget.routeInfo.steps.isNotEmpty) {
      final firstStep = widget.routeInfo.steps[0];
      initialTarget = LatLng(
        firstStep.location.latitude,
        firstStep.location.longitude,
      );
      initialBearing =
          RoutePreviewHelper.calculateStepBearing(widget.routeInfo.steps, 0);
    } else if (widget.routeInfo.points.isNotEmpty) {
      final center = RoutePreviewHelper.getRouteCenter(widget.routeInfo.points);
      initialTarget = LatLng(center.latitude, center.longitude);
    } else {
      initialTarget = const LatLng(0, 0);
    }

    return MapLibreMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 17.5, // Tighter zoom for street-level detail
        bearing: initialBearing,
      ),
      styleString:
          isDark ? AppConstants.darkStyleUrl : AppConstants.osmStyleUrl,
      onMapCreated: _onMapCreated,
      compassEnabled: false,
      myLocationEnabled: false,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
    );
  }

  Widget _buildFloatingCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Half: Back button + Title
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white70 : Colors.black87,
                    size: context.sp(24),
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Text(
                    'Route Preview',
                    style: TextStyle(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),

          // Bottom Half: REACTIVE instruction text from current step
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentIcon, // ← REACTIVE to _currentIndex
                    color: const Color(0xFF4285F4),
                    size: context.sp(24),
                  ),
                ),
                SizedBox(width: context.w(14)),
                Expanded(
                  child: Text(
                    _currentInstruction, // ← REACTIVE to _currentIndex
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.r(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: context.w(10),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(24)),
                bottomLeft: Radius.circular(context.r(24)),
              ),
              onTap: _currentIndex > 0 && !_isAnimating ? _previousStep : null,
              child: Padding(
                padding: EdgeInsets.all(context.w(12)),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _currentIndex > 0
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                  size: context.sp(24),
                ),
              ),
            ),
          ),
          // Step counter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            child: Text(
              '${_currentIndex + 1}/${widget.routeInfo.steps.length}',
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          // Next button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(context.r(24)),
                bottomRight: Radius.circular(context.r(24)),
              ),
              onTap: _currentIndex < widget.routeInfo.steps.length - 1 &&
                      !_isAnimating
                  ? _nextStep
                  : null,
              child: Padding(
                padding: EdgeInsets.all(context.w(12)),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _currentIndex < widget.routeInfo.steps.length - 1
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                  size: context.sp(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
    await _addPreviewIcons();
    await _drawRoute();
    if (widget.routeInfo.steps.isNotEmpty) {
      await _drawStepMarker(_currentIndex);
    }
  }

  Future<void> _addPreviewIcons() async {
    if (_isIconLoaded || _mapController == null || !mounted) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      textPainter.text = TextSpan(
        text: String.fromCharCode(Icons.arrow_upward_rounded.codePoint),
        style: TextStyle(
          fontSize: 100.0,
          fontFamily: Icons.arrow_upward_rounded.fontFamily,
          package: Icons.arrow_upward_rounded.fontPackage,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(2, 2),
            ),
          ],
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);

      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      // Dispose the image to prevent memory leaks
      image.dispose();
      picture.dispose();

      if (bytes != null && mounted && _mapController != null) {
        await _mapController!.addImage(
          'direction-arrow',
          bytes.buffer.asUint8List(),
        );
        _isIconLoaded = true;
      }
    } catch (e) {
      if (mounted) {
        _isIconLoaded = true;
      }
    }
  }

  /// Draw the FULL route using ALL polyline points (not step locations)
  /// This ensures the blue line follows every curve and turn
  Future<void> _drawRoute() async {
    if (_mapController == null || widget.routeInfo.points.isEmpty) return;

    try {
      // Convert ALL polyline points to LatLng for the line
      final List<LatLng> routePoints = widget.routeInfo.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      await _mapController!.addLine(
        LineOptions(
          geometry: routePoints,
          lineColor: '#4285F4', // Google Blue
          lineWidth: 6.0,
          lineOpacity: 1.0, // Full opacity for vibrant color
          lineJoin: 'round',
        ),
      );
    } catch (e) {
      // Ignore line drawing errors
    }
  }

  /// Draw step marker at EXACT step coordinate
  /// Arrow points UP (0.0) since camera bearing handles rotation
  Future<void> _drawStepMarker(int index) async {
    if (_mapController == null || !_isIconLoaded) return;

    try {
      // Clear previous markers to prevent memory leaks
      await _mapController!.clearSymbols();

      final step = widget.routeInfo.steps[index];

      // Arrow points UP (0.0) - camera bearing rotates map so arrow points forward
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(step.location.latitude, step.location.longitude),
          iconImage: 'direction-arrow',
          iconSize: 1.0,
          iconRotate: 0.0, // UP direction, camera handles rotation
          iconAnchor: 'center',
        ),
      );
    } catch (e) {
      // Ignore symbol errors
    }
  }

  /// Animate camera to step and update all visuals
  /// This function MUST:
  /// 1. Update index FIRST (text updates instantly)
  /// 2. Animate camera to step location
  /// 3. Update arrow marker
  Future<void> _animateToStep(int index) async {
    if (_mapController == null ||
        index >= widget.routeInfo.steps.length ||
        _isAnimating) return;

    _isAnimating = true;

    // CRITICAL: setState BEFORE animation - text updates INSTANTLY
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    final step = widget.routeInfo.steps[index];
    final bearing = RoutePreviewHelper.calculateBearingFromPolyline(
        widget.routeInfo.points, step);

    // Update arrow marker BEFORE animation (so it moves with camera)
    try {
      await _mapController!.clearSymbols();
    } catch (_) {}

    try {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(step.location.latitude, step.location.longitude),
          iconImage: 'direction-arrow',
          iconSize: 1.0,
          iconRotate: 0.0,
          iconAnchor: 'center',
        ),
      );
    } catch (_) {}

    // Animate camera AFTER marker is placed
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(step.location.latitude, step.location.longitude),
            zoom: 17.5,
            bearing: bearing,
            tilt: 0.0,
          ),
        ),
        duration: const Duration(milliseconds: 800),
      );
    } catch (_) {}

    _isAnimating = false;
  }

  /// Navigate to next step - REACTIVE to instruction text
  void _nextStep() {
    if (_currentIndex < widget.routeInfo.steps.length - 1 && !_isAnimating) {
      _animateToStep(_currentIndex + 1);
    }
  }

  /// Navigate to previous step - REACTIVE to instruction text
  void _previousStep() {
    if (_currentIndex > 0 && !_isAnimating) {
      _animateToStep(_currentIndex - 1);
    }
  }

  @override
  void dispose() {
    // Don't dispose _mapController - MapLibreMap widget handles it
    _mapController = null;
    super.dispose();
  }
}
