import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/widgets/map_controls_overlay.dart';
import 'package:mapy/features/map/widgets/navigation_overlay.dart';

/// Bottom overlay containing map controls, trip bar, and route info panel.
class BottomMapControls extends StatelessWidget {
  final bool isDark;
  final bool isNavigating;
  final bool is3dMode;
  final bool hasRoute;
  final bool isFetchingRoute;
  final double bearing;
  final RouteInfo routeInfo;
  final TravelMode travelMode;
  final Widget tripBar;
  final VoidCallback onRelocate;
  final VoidCallback onLayers;
  final VoidCallback onTogglePerspective;
  final VoidCallback onResetBearing;
  final VoidCallback onClearRoute;
  final Function(TravelMode) onModeSelect;
  final List<RouteAlternative>? routeAlternatives;
  final int selectedAlternativeIndex;
  final VoidCallback? onShowAlternatives;
  final VoidCallback? onShareLocation;

  const BottomMapControls({
    super.key,
    required this.isDark,
    required this.isNavigating,
    required this.is3dMode,
    required this.hasRoute,
    required this.isFetchingRoute,
    required this.bearing,
    required this.routeInfo,
    required this.travelMode,
    required this.tripBar,
    required this.onRelocate,
    required this.onLayers,
    required this.onTogglePerspective,
    required this.onResetBearing,
    required this.onClearRoute,
    required this.onModeSelect,
    this.routeAlternatives,
    this.selectedAlternativeIndex = 0,
    this.onShowAlternatives,
    this.onShareLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMapControls(context),
          SizedBox(height: context.h(16)),
          _buildTripBarWithAnimation(),
          if (hasRoute) ...[
            SizedBox(height: context.h(12)),
            RepaintBoundary(
              child: RouteInfoPanel(
                routeInfo: routeInfo,
                isNavigating: isNavigating,
                travelMode: travelMode,
                isDark: isDark,
                isFetchingRoute: isFetchingRoute,
                onClear: onClearRoute,
                onModeSelect: onModeSelect,
                alternatives: routeAlternatives,
                selectedAlternativeIndex: selectedAlternativeIndex,
                onShowAlternatives: onShowAlternatives,
              ),
            ),
          ],
          if (!hasRoute) SizedBox(height: context.h(40)),
        ],
      ),
    );
  }

  Widget _buildMapControls(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.w(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasRoute) SizedBox(height: context.h(260)),
          Align(
            alignment: Alignment.centerRight,
            child: MapControlsOverlay(
              isDark: isDark,
              isNavigating: isNavigating,
              is3dMode: is3dMode,
              hasRoute: hasRoute,
              bearing: bearing,
              onRelocate: onRelocate,
              onLayers: onLayers,
              onTogglePerspective: onTogglePerspective,
              onResetBearing: onResetBearing,
              showLayersButton: false,
              showAtTop: false,
              showOnlyLayers: false,
              onShareLocation: onShareLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripBarWithAnimation() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: tripBar,
        ),
      ),
    );
  }
}
