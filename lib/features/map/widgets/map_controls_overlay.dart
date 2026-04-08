import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';

class MapControlsOverlay extends StatefulWidget {
  final bool isDark;
  final bool isNavigating;
  final bool is3dMode;
  final bool hasRoute;
  final double bearing;
  final VoidCallback onRelocate;
  final VoidCallback onLayers;
  final VoidCallback onTogglePerspective;
  final VoidCallback onResetBearing;
  final VoidCallback? onShareLocation;
  final bool showLayersButton;
  final bool showAtTop;
  final bool showOnlyLayers;
  final double? currentLat;
  final double? currentLng;
  final LocationFollowMode locationFollowMode;

  const MapControlsOverlay({
    super.key,
    required this.isDark,
    required this.isNavigating,
    required this.is3dMode,
    required this.hasRoute,
    required this.bearing,
    required this.onRelocate,
    required this.onLayers,
    required this.onTogglePerspective,
    required this.onResetBearing,
    this.onShareLocation,
    this.showLayersButton = true,
    this.showAtTop = false,
    this.showOnlyLayers = false,
    this.currentLat,
    this.currentLng,
    this.locationFollowMode = LocationFollowMode.none,
  });

  static Widget buildLayersButton({
    required bool isDark,
    required VoidCallback onLayers,
  }) {
    return Builder(
      builder: (context) {
        final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
        return _LayersButton(
          onTap: onLayers,
          bgColor: bgColor,
        );
      },
    );
  }

  @override
  State<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends State<MapControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppConstants.modalBackground : Colors.white;
    if (widget.showOnlyLayers) {
      return _LayersButton(
        onTap: widget.onLayers,
        bgColor: bgColor,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: widget.bearing.abs() >= 1.0
                ? Padding(
                    key: const ValueKey('compass_visible'),
                    padding: EdgeInsets.only(bottom: context.h(12)),
                    child: _GoogleMapsCompassButton(
                      bearing: widget.bearing,
                      onTap: widget.onResetBearing,
                      isDark: widget.isDark,
                      bgColor: bgColor,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('compass_hidden')),
          ),
        ),
        _LocateMe3dButton(
          isNavigating: widget.isNavigating,
          isDark: widget.isDark,
          bgColor: bgColor,
          onRelocate: widget.onRelocate,
          locationFollowMode: widget.locationFollowMode,
        ),
        if (widget.showLayersButton) ...[
          SizedBox(height: context.h(12)),
          _LayersButton(
            onTap: widget.onLayers,
            bgColor: bgColor,
          ),
        ],
      ],
    );
  }
}

class _GoogleMapsCompassButton extends StatefulWidget {
  final double bearing;
  final VoidCallback onTap;
  final bool isDark;
  final Color bgColor;

  const _GoogleMapsCompassButton({
    required this.bearing,
    required this.onTap,
    required this.isDark,
    required this.bgColor,
  });

  @override
  State<_GoogleMapsCompassButton> createState() =>
      _GoogleMapsCompassButtonState();
}

class _GoogleMapsCompassButtonState extends State<_GoogleMapsCompassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = context.w(40);
    final needleSize = size * 0.62;

    return Semantics(
      label: 'Reset map bearing to north',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: context.w(12),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.bgColor.withValues(alpha: 0.90),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -widget.bearing * math.pi / 180,
                      child: SizedBox(
                        width: needleSize,
                        height: needleSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(needleSize, needleSize),
                              painter: _CompassNeedlePainter(),
                            ),
                            Positioned(
                              top: 0,
                              child: Text(
                                'N',
                                style: TextStyle(
                                  fontSize: context.sp(8),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.redAccent,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final hw = size.width * 0.20;
    final hn = size.height * 0.44;
    final hs = size.height * 0.44;

    // North half — red
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - hn)
        ..lineTo(cx + hw, cy)
        ..lineTo(cx - hw, cy)
        ..close(),
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill,
    );

    // South half — white/gray
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + hs)
        ..lineTo(cx + hw, cy)
        ..lineTo(cx - hw, cy)
        ..close(),
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.fill,
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.07,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CompassNeedlePainter old) => false;
}

class _LocateMe3dButton extends StatefulWidget {
  final bool isNavigating;
  final bool isDark;
  final Color bgColor;
  final VoidCallback onRelocate;
  final LocationFollowMode locationFollowMode;

  const _LocateMe3dButton({
    required this.isNavigating,
    required this.isDark,
    required this.bgColor,
    required this.onRelocate,
    this.locationFollowMode = LocationFollowMode.none,
  });

  @override
  State<_LocateMe3dButton> createState() => _LocateMe3dButtonState();
}

class _LocateMe3dButtonState extends State<_LocateMe3dButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Icon + colour logic follows Google Maps states:
    //  navigating          → blue navigation arrow (existing behaviour)
    //  follow mode none    → grey location_searching (no tracking)
    //  follow mode follow  → blue my_location (solid, tracking position)
    //  follow mode compass → blue navigation (tracking + rotating with heading)
    late final IconData icon;
    late final Color iconColor;

    if (widget.isNavigating) {
      icon = Icons.navigation_rounded;
      iconColor = Colors.blueAccent;
    } else {
      switch (widget.locationFollowMode) {
        case LocationFollowMode.none:
          icon = Icons.location_searching_rounded;
          iconColor = widget.isDark ? Colors.white70 : Colors.black54;
        case LocationFollowMode.follow:
          icon = Icons.my_location_rounded;
          iconColor = Colors.blueAccent;
        case LocationFollowMode.compass:
          icon = Icons.navigation_rounded;
          iconColor = Colors.blueAccent;
      }
    }

    return Semantics(
      label: 'My location',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onRelocate();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: context.w(12),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.bgColor.withValues(alpha: 0.85),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.w(14)),
                    child: Icon(icon, color: iconColor, size: context.sp(24)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMapButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;
  final String semanticLabel;

  const _AnimatedMapButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bgColor,
    required this.semanticLabel,
  });

  @override
  State<_AnimatedMapButton> createState() => _AnimatedMapButtonState();
}

class _AnimatedMapButtonState extends State<_AnimatedMapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: context.w(12),
                offset: Offset(0, context.h(4)),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bgColor.withValues(alpha: 0.85),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.w(14)),
                  child: Icon(widget.icon,
                      color: widget.color, size: context.sp(24)),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _LayersButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color bgColor;

  const _LayersButton({
    required this.onTap,
    required this.bgColor,
  });

  @override
  State<_LayersButton> createState() => _LayersButtonState();
}

class _LayersButtonState extends State<_LayersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Map layers',
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.bgColor.withValues(alpha: 0.9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Center(
                child: Icon(Icons.layers_rounded,
                    color: Colors.blueAccent, size: 24),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
