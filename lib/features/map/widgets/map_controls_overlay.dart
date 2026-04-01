import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
class MapControlsOverlay extends StatelessWidget {
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
        return _button(
          context: context,
          icon: Icons.layers_rounded,
          onTap: onLayers,
          color: Colors.blueAccent,
          bgColor: bgColor,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
    if (showOnlyLayers) {
      return _button(
        context: context,
        icon: Icons.layers_rounded,
        onTap: onLayers,
        color: Colors.blueAccent,
        bgColor: bgColor,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bearing.abs() >= 0.1)
          GestureDetector(
            onTap: onResetBearing,
            child: Transform.rotate(
              angle: -bearing * (3.14159 / 180),
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
        _button(
          context: context,
          icon: isNavigating
              ? Icons.navigation_rounded
              : Icons.my_location_rounded,
          onTap: onRelocate,
          color: isNavigating
              ? Colors.blueAccent
              : (isDark ? Colors.white : Colors.black87),
          bgColor: bgColor,
        ),
        if (showLayersButton) ...[
          SizedBox(height: context.h(12)),
          _button(
            context: context,
            icon: Icons.layers_rounded,
            onTap: onLayers,
            color: Colors.blueAccent,
            bgColor: bgColor,
          ),
        ],
        SizedBox(height: context.h(12)),
        _button(
          context: context,
          icon: is3dMode ? Icons.apartment_rounded : Icons.map_rounded,
          onTap: onTogglePerspective,
          color: Colors.orangeAccent,
          bgColor: bgColor,
        ),
        SizedBox(height: context.h(12)),
        if (!hasRoute)
          _button(
            context: context,
            icon: Icons.share_location_rounded,
            onTap: onShareLocation ?? () {},
            color: Colors.green,
            bgColor: bgColor,
          ),
      ],
    );
  }
  static Widget _button({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
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
            child: Material(
              color: bgColor.withValues(alpha: 0.85),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(context.r(30)),
                child: Padding(
                  padding: EdgeInsets.all(context.w(14)),
                  child: Icon(icon, color: color, size: context.sp(24)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
