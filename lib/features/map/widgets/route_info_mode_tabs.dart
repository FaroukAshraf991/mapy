import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/models/route_info.dart';

class RouteInfoModeTabs extends StatelessWidget {
  final TravelMode travelMode;
  final bool isDark;
  final bool isFetchingRoute;
  final RouteInfo routeInfo;
  final Function(TravelMode) onModeSelect;

  const RouteInfoModeTabs({
    super.key,
    required this.travelMode,
    required this.isDark,
    required this.isFetchingRoute,
    required this.routeInfo,
    required this.onModeSelect,
  });

  @override
  Widget build(BuildContext context) {
    const modes = <(TravelMode, IconData)>[
      (TravelMode.driving, Icons.directions_car_rounded),
      (TravelMode.motorcycle, Icons.motorcycle_rounded),
      (TravelMode.bicycle, Icons.directions_bike_rounded),
      (TravelMode.foot, Icons.directions_walk_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modes.map((entry) {
          final (mode, icon) = entry;
          final isSelected = travelMode == mode;
          final label = isSelected
              ? (isFetchingRoute
                  ? AppStrings.fetchingEtaPlaceholder
                  : routeInfo.etaText.replaceFirst('~', ''))
              : AppStrings.inactiveModeEta;
          final color =
              isSelected ? Colors.blueAccent : (isDark ? Colors.white38 : Colors.black38);
          return GestureDetector(
            onTap: () => onModeSelect(mode),
            child: Container(
              margin: EdgeInsets.only(right: context.w(16)),
              padding: EdgeInsets.only(bottom: context.h(5)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                    width: AppConstants.modeTabIndicatorWidth,
                  ),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: context.sp(14), color: color),
                SizedBox(width: context.w(4)),
                Text(label,
                    style: TextStyle(
                      color: color,
                      fontSize: context.sp(11),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
