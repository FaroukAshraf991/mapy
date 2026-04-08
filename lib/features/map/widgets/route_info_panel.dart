import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/widgets/constrained_content_box.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/widgets/route_info_default_content.dart';
class RouteInfoPanel extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isNavigating, isDark;
  final TravelMode travelMode;
  final VoidCallback onClear;
  final Function(TravelMode) onModeSelect;
  final List<RouteAlternative>? alternatives;
  final int selectedAlternativeIndex;
  final VoidCallback? onShowAlternatives;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onPreview;
  final bool isSwapped;
  final bool isFetchingRoute;
  const RouteInfoPanel(
      {super.key,
      required this.routeInfo,
      required this.isNavigating,
      required this.travelMode,
      required this.isDark,
      this.isFetchingRoute = false,
      required this.onClear,
      required this.onModeSelect,
      this.alternatives,
      this.selectedAlternativeIndex = 0,
      this.onShowAlternatives,
      this.onStartNavigation,
      this.onPreview,
      this.isSwapped = false});
  @override
  Widget build(BuildContext context) {
    if (!routeInfo.hasRoute) return const SizedBox.shrink();
    final r = isNavigating ? context.r(16) : context.r(28);
    return ConstrainedContentBox(
      child: Container(
      margin: EdgeInsets.only(
          left: context.w(16),
          right: context.w(16),
          bottom: MediaQuery.of(context).padding.bottom + context.h(16)),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(r), boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: context.w(25),
            offset: Offset(0, context.h(8)))
      ]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isNavigating ? context.w(16) : context.w(16),
                  vertical: isNavigating ? context.h(12) : context.h(14)),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(r),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.4),
                      width: 1.5)),
              child: isNavigating
                  ? _buildCompactDrivingMode(context)
                  : _buildDefaultMode(context),
            ),
          )),
    ),
    );
  }
  Widget _buildDefaultMode(BuildContext context) {
    return RouteInfoDefaultContent(
      routeInfo: routeInfo,
      travelMode: travelMode,
      isDark: isDark,
      isFetchingRoute: isFetchingRoute,
      isSwapped: isSwapped,
      onStartNavigation: onStartNavigation,
      onPreview: onPreview,
      onClear: onClear,
      onModeSelect: onModeSelect,
      alternatives: alternatives,
      selectedAlternativeIndex: selectedAlternativeIndex,
      onShowAlternatives: onShowAlternatives,
    );
  }
  Widget _buildCompactDrivingMode(BuildContext context) {
    return Row(children: [
      Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: Icon(_getIconForMode(travelMode),
              color: Colors.blueAccent, size: context.sp(24))),
      SizedBox(width: context.w(12)),
      Expanded(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(routeInfo.etaText,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: context.sp(18),
                    fontWeight: FontWeight.w900)),
            Text(routeInfo.distanceText,
                style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600)),
          ])),
    ]);
  }
  IconData _getIconForMode(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Icons.directions_car_rounded;
      case TravelMode.motorcycle:
        return Icons.motorcycle_rounded;
      case TravelMode.bicycle:
        return Icons.directions_bike_rounded;
      case TravelMode.foot:
        return Icons.directions_walk_rounded;
    }
  }
}
