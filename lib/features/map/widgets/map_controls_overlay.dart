import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

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
  });

  static Widget buildLayersButton({
    required bool isDark,
    required VoidCallback onLayers,
  }) {
    return Builder(
      builder: (context) {
        final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
        return _AnimatedMapButton(
          icon: Icons.layers_rounded,
          onTap: onLayers,
          color: Colors.blueAccent,
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
      return _AnimatedMapButton(
        icon: Icons.layers_rounded,
        onTap: widget.onLayers,
        color: Colors.blueAccent,
        bgColor: bgColor,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.bearing.abs() >= 0.1)
          GestureDetector(
            onTap: widget.onResetBearing,
            child: Transform.rotate(
              angle: -widget.bearing * (3.14159 / 180),
              child: Container(
                width: context.w(48),
                height: context.w(48),
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
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor.withValues(alpha: 0.85),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: -0.785398,
                            child: Icon(
                              Icons.navigation_rounded,
                              size: context.sp(28),
                              color: Colors.redAccent,
                            ),
                          ),
                          Positioned(
                            top: context.h(6),
                            child: Text(
                              'N',
                              style: TextStyle(
                                fontSize: context.sp(10),
                                fontWeight: FontWeight.w900,
                                color: Colors.redAccent,
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
        SizedBox(height: context.h(12)),
        _AnimatedMapButton(
          icon: widget.isNavigating
              ? Icons.navigation_rounded
              : Icons.my_location_rounded,
          onTap: widget.onRelocate,
          color: widget.isNavigating
              ? Colors.blueAccent
              : (widget.isDark ? Colors.white : Colors.black87),
          bgColor: bgColor,
        ),
        if (widget.showLayersButton) ...[
          SizedBox(height: context.h(12)),
          _AnimatedMapButton(
            icon: Icons.layers_rounded,
            onTap: widget.onLayers,
            color: Colors.blueAccent,
            bgColor: bgColor,
          ),
        ],
        SizedBox(height: context.h(12)),
        _AnimatedMapButton(
          icon: widget.is3dMode ? Icons.apartment_rounded : Icons.map_rounded,
          onTap: widget.onTogglePerspective,
          color: Colors.orangeAccent,
          bgColor: bgColor,
        ),
        SizedBox(height: context.h(12)),
        if (!widget.hasRoute)
          _AnimatedMapButton(
            icon: Icons.share_location_rounded,
            onTap: widget.onShareLocation ?? () {},
            color: Colors.green,
            bgColor: bgColor,
          ),
      ],
    );
  }
}

class _AnimatedMapButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  const _AnimatedMapButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bgColor,
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
    return GestureDetector(
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Container(
                  color: widget.bgColor.withValues(alpha: 0.85),
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
