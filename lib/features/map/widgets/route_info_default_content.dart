import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/widgets/route_info_mode_tabs.dart';
import 'package:mapy/features/map/widgets/route_info_stats.dart';

class RouteInfoDefaultContent extends StatelessWidget {
  final RouteInfo routeInfo;
  final TravelMode travelMode;
  final bool isDark;
  final bool isFetchingRoute;
  final bool isSwapped;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onPreview;
  final VoidCallback onClear;
  final Function(TravelMode) onModeSelect;
  final List<RouteAlternative>? alternatives;
  final int selectedAlternativeIndex;
  final VoidCallback? onShowAlternatives;

  const RouteInfoDefaultContent({
    super.key,
    required this.routeInfo,
    required this.travelMode,
    required this.isDark,
    this.isFetchingRoute = false,
    this.isSwapped = false,
    this.onStartNavigation,
    this.onPreview,
    required this.onClear,
    required this.onModeSelect,
    this.alternatives,
    this.selectedAlternativeIndex = 0,
    this.onShowAlternatives,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        SizedBox(height: context.h(8)),
        RouteInfoModeTabs(
          travelMode: travelMode,
          isDark: isDark,
          isFetchingRoute: isFetchingRoute,
          routeInfo: routeInfo,
          onModeSelect: onModeSelect,
        ),
        Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            thickness: 1,
            height: context.h(14)),
        RouteInfoStats(
          routeInfo: routeInfo,
          isDark: isDark,
          isFetchingRoute: isFetchingRoute,
        ),
        SizedBox(height: context.h(10)),
        _buildActionRow(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          _modeName(travelMode),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: context.sp(20),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        _iconBtn(context, Icons.close_rounded, onClear),
      ],
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(context.r(AppConstants.iconButtonBorderRadius)),
        child: Container(
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: isDark ? Colors.white70 : Colors.black54,
              size: context.sp(20)),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSwapped ? onPreview : onStartNavigation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: context.h(11)),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(context.r(AppConstants.pillBorderRadius)),
              ),
              elevation: 0,
            ),
            icon: Icon(
                isSwapped
                    ? Icons.compare_arrows_rounded
                    : Icons.navigation_rounded,
                size: context.sp(16)),
            label: Text(
              isSwapped ? AppStrings.preview : AppStrings.start,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: context.sp(13),
                letterSpacing: AppConstants.navButtonLetterSpacing,
              ),
            ),
          ),
        ),
        if (alternatives != null && alternatives!.isNotEmpty) ...[
          SizedBox(width: context.w(12)),
          GestureDetector(
            onTap: onShowAlternatives,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(12), vertical: context.h(11)),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(context.r(AppConstants.pillBorderRadius)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.route_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: context.sp(15)),
                SizedBox(width: context.w(5)),
                Text('${alternatives!.length} ${AppStrings.routes}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(11),
                    )),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  String _modeName(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return AppStrings.modeDrive;
      case TravelMode.motorcycle:
        return AppStrings.modeMotorcycle;
      case TravelMode.bicycle:
        return AppStrings.modeBicycle;
      case TravelMode.foot:
        return AppStrings.modeWalk;
    }
  }
}
