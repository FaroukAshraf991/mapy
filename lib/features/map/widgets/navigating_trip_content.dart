import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';

class NavigatingTripContent extends StatelessWidget {
  final bool isDark;
  final RouteInfo routeInfo;
  final TravelMode travelMode;
  final VoidCallback onExitNavigation;

  const NavigatingTripContent({
    super.key,
    required this.isDark,
    required this.routeInfo,
    required this.travelMode,
    required this.onExitNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildModeIcon(context),
        SizedBox(width: context.w(10)),
        _buildRouteStats(context),
        if (!context.isTablet) _buildDivider(context),
        if (!context.isTablet) Expanded(child: _buildGuidanceText(context)),
        if (context.isTablet) const Spacer(),
        _buildExitButton(context),
      ],
    );
  }

  Widget _buildModeIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconForMode(travelMode),
        color: Colors.blueAccent,
        size: context.sp(22),
      ),
    );
  }

  Widget _buildRouteStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          routeInfo.etaText,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: context.sp(16),
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          routeInfo.distanceText,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: context.sp(12),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: AppConstants.navDividerWidth,
      height: context.h(40),
      color: isDark ? Colors.white24 : Colors.black12,
      margin: EdgeInsets.symmetric(horizontal: context.w(12)),
    );
  }

  Widget _buildGuidanceText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.activeGuidance,
          style: TextStyle(
            fontSize: context.sp(10),
            fontWeight: FontWeight.w900,
            color: Colors.blueAccent,
            letterSpacing: AppConstants.navLabelLetterSpacing,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          AppStrings.driveSafely,
          style: TextStyle(
            fontSize: context.sp(17),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: AppConstants.navSubtitleLetterSpacing,
          ),
        ),
      ],
    );
  }

  Widget _buildExitButton(BuildContext context) {
    final size = context.r(48);
    return GestureDetector(
      onTap: onExitNavigation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: context.w(8),
              offset: Offset(0, context.h(3)),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.sp(18),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForMode(TravelMode mode) {
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
