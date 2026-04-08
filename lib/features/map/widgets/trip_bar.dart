import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/widgets/navigating_trip_content.dart';
import 'package:mapy/features/map/widgets/pre_nav_trip_content.dart';

/// The "Where would you like to go?" floating bar with START / PREVIEW / EXIT buttons.
class TripBar extends StatelessWidget {
  final bool hasRoute;
  final bool isNavigating;
  final bool isDark;
  final bool isSwapped;
  final VoidCallback onTap;
  final VoidCallback onStartNavigation;
  final VoidCallback onExitNavigation;
  final VoidCallback? onPreview;
  final RouteInfo? routeInfo;
  final TravelMode? travelMode;
  final bool isFetchingRoute;

  const TripBar({
    super.key,
    required this.hasRoute,
    required this.isNavigating,
    required this.isDark,
    this.isSwapped = false,
    required this.onTap,
    required this.onStartNavigation,
    required this.onExitNavigation,
    this.onPreview,
    this.routeInfo,
    this.travelMode,
    this.isFetchingRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('trip_bar_${hasRoute}_$isNavigating'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: context.w(25),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: isDark
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(context.r(28)),
            child: InkWell(
              onTap: (isNavigating || hasRoute) ? null : onTap,
              borderRadius: BorderRadius.circular(context.r(28)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(20), vertical: context.h(18)),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(context.r(28)),
                ),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isNavigating && routeInfo != null && travelMode != null) {
      return NavigatingTripContent(
        isDark: isDark,
        routeInfo: routeInfo!,
        travelMode: travelMode!,
        onExitNavigation: onExitNavigation,
      );
    }
    if (hasRoute && !isNavigating && routeInfo != null && travelMode != null) {
      return PreNavTripContent(
        isDark: isDark,
        routeInfo: routeInfo!,
        travelMode: travelMode!,
        isFetchingRoute: isFetchingRoute,
        isSwapped: isSwapped,
        onStart: onStartNavigation,
        onPreview: onPreview,
      );
    }
    return Row(
      children: [
        Expanded(child: _buildText(context)),
        if (hasRoute && !isNavigating && !isSwapped) _buildStartButton(context),
        if (hasRoute && !isNavigating && isSwapped)
          _buildPreviewButton(context),
        if (isNavigating) _buildExitButton(context),
      ],
    );
  }

  Widget _buildText(BuildContext context) {
    final statusLabel = isNavigating
        ? AppStrings.activeGuidance
        : (hasRoute ? AppStrings.estimatedTravelTime : AppStrings.readyToGo);
    final statusColor = isNavigating
        ? Colors.blueAccent
        : (isDark ? Colors.white38 : Colors.black38);
    final subtitle = isNavigating
        ? AppStrings.driveSafely
        : (hasRoute ? AppStrings.routeCalculated : AppStrings.whereToGo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: context.sp(10),
            fontWeight: FontWeight.w900,
            color: statusColor,
            letterSpacing: AppConstants.navLabelLetterSpacing,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: context.sp(20),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: AppConstants.navSubtitleLetterSpacing,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onStartNavigation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(24), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(AppConstants.navButtonBorderRadius)),
        ),
        elevation: AppConstants.navButtonElevation,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      icon: Icon(Icons.navigation_rounded, size: context.sp(22)),
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

  Widget _buildPreviewButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPreview,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(24), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(AppConstants.navButtonBorderRadius)),
        ),
        elevation: AppConstants.navButtonElevation,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      icon: Icon(Icons.compare_arrows_rounded, size: context.sp(22)),
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
}
