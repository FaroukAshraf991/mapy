import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';

class RouteInfoStats extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isDark;
  final bool isFetchingRoute;

  const RouteInfoStats({
    super.key,
    required this.routeInfo,
    required this.isDark,
    this.isFetchingRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (routeInfo.durationSeconds / 60).round();
    final etaNum = minutes < 60 ? '$minutes' : '${minutes ~/ 60}';
    final etaUnit = minutes < 60
        ? AppStrings.etaUnitMin
        : (minutes % 60 == 0
            ? AppStrings.etaUnitHr
            : '${AppStrings.etaUnitHr} ${minutes % 60}m');
    final arrival =
        DateTime.now().add(Duration(seconds: routeInfo.durationSeconds.round()));
    final h = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final m = arrival.minute.toString().padLeft(2, '0');
    final period =
        arrival.hour >= 12 ? AppStrings.pmPeriod : AppStrings.amPeriod;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFetchingRoute ? AppStrings.fetchingEtaPlaceholder : etaNum,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: context.sp(30),
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            Text(etaUnit,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.h(4)),
              Text(
                isFetchingRoute
                    ? AppStrings.calculatingRoute
                    : '${AppStrings.arrive} $h:$m $period · ${AppStrings.fastestRoute}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: context.sp(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(routeInfo.distanceText,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
