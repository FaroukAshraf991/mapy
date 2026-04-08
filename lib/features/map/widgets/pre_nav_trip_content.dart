import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';

class PreNavTripContent extends StatelessWidget {
  final bool isDark;
  final RouteInfo routeInfo;
  final TravelMode travelMode;
  final bool isFetchingRoute;
  final bool isSwapped;
  final VoidCallback onStart;
  final VoidCallback? onPreview;

  const PreNavTripContent({
    super.key,
    required this.isDark,
    required this.routeInfo,
    required this.travelMode,
    this.isFetchingRoute = false,
    this.isSwapped = false,
    required this.onStart,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildModeIcon(context),
        SizedBox(width: context.w(10)),
        _buildRouteStats(context),
        _buildDivider(context),
        Expanded(child: _buildLabel(context)),
        _buildActionButton(context),
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
    if (isFetchingRoute) {
      return SizedBox(
        width: context.sp(18),
        height: context.sp(18),
        child: CircularProgressIndicator(
          strokeWidth: AppConstants.modeTabIndicatorWidth,
          color: Colors.blueAccent,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          routeInfo.etaText,
          style: TextStyle(
            color: Colors.blueAccent,
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

  Widget _buildLabel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.estimatedTravelTime,
          style: TextStyle(
            fontSize: context.sp(10),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: AppConstants.navLabelLetterSpacing,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          isFetchingRoute ? AppStrings.calculating : AppStrings.routeCalculated,
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

  Widget _buildActionButton(BuildContext context) {
    if (isSwapped) {
      return ElevatedButton.icon(
        onPressed: onPreview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: context.w(20), vertical: context.h(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(AppConstants.navButtonBorderRadius)),
          ),
          elevation: AppConstants.navButtonElevation,
          shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
        ),
        icon: Icon(Icons.compare_arrows_rounded, size: context.sp(20)),
        label: Text(
          AppStrings.preview,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: context.sp(16),
            letterSpacing: AppConstants.navButtonLetterSpacing,
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onStart,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(20), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(AppConstants.navButtonBorderRadius)),
        ),
        elevation: AppConstants.navButtonElevation,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      icon: Icon(Icons.navigation_rounded, size: context.sp(20)),
      label: Text(
        AppStrings.start,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: context.sp(16),
          letterSpacing: AppConstants.navButtonLetterSpacing,
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
