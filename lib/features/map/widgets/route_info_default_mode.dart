import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/models/map_enums.dart';

class RouteInfoDefaultMode extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isDark;
  final bool isFetchingRoute;
  final List<dynamic>? alternatives;
  final VoidCallback? onShowAlternatives;
  final Widget Function(BuildContext, TravelMode, IconData) modeChip;
  final Widget Function(BuildContext) closeButton;

  const RouteInfoDefaultMode({
    super.key,
    required this.routeInfo,
    required this.isDark,
    this.isFetchingRoute = false,
    this.alternatives,
    this.onShowAlternatives,
    required this.modeChip,
    required this.closeButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    modeChip(context, TravelMode.driving,
                        Icons.directions_car_rounded),
                    SizedBox(width: context.w(6)),
                    modeChip(context, TravelMode.motorcycle,
                        Icons.motorcycle_rounded),
                    SizedBox(width: context.w(6)),
                    modeChip(context, TravelMode.bicycle,
                        Icons.directions_bike_rounded),
                    SizedBox(width: context.w(6)),
                    modeChip(context, TravelMode.foot,
                        Icons.directions_walk_rounded),
                  ],
                ),
              ),
            ),
            closeButton(context),
          ],
        ),
        SizedBox(height: context.h(20)),
        if (isFetchingRoute)
          Row(
            children: [
              SizedBox(
                width: context.sp(20),
                height: context.sp(20),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.blueAccent),
              ),
              SizedBox(width: context.w(12)),
              Text('Calculating…',
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: context.sp(20),
                      fontWeight: FontWeight.w800)),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(routeInfo.etaText,
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: context.sp(24),
                      fontWeight: FontWeight.w900)),
              SizedBox(height: context.h(4)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.w(8), vertical: context.h(4)),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(8))),
                    child: Text(routeInfo.distanceText,
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  if (alternatives != null && alternatives!.isNotEmpty)
                    GestureDetector(
                      onTap: onShowAlternatives,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(14), vertical: context.h(8)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                Colors.green.withValues(alpha: 0.2),
                                Colors.teal.withValues(alpha: 0.15)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(context.r(12)),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.green.withValues(alpha: 0.15),
                                blurRadius: context.w(8),
                                offset: Offset(0, context.h(2)))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route_rounded,
                                color: Colors.green, size: context.sp(18)),
                            SizedBox(width: context.w(6)),
                            Text('${alternatives!.length} Routes',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: context.sp(13))),
                            SizedBox(width: context.w(4)),
                            Icon(Icons.expand_more_rounded,
                                color: Colors.green.withValues(alpha: 0.8),
                                size: context.sp(16)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: context.h(6)),
              Text('Fastest route via Main St',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w700)),
            ],
          ),
      ],
    );
  }
}
