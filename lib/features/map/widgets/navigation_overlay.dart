import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/models/map_enums.dart';

class NavigationGuidanceBar extends StatelessWidget {
  final RouteInfo routeInfo;
  final int currentStepIndex;
  final double distanceToNextStep;
  final bool isDark;
  final double currentSpeed;

  const NavigationGuidanceBar({
    super.key,
    required this.routeInfo,
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.isDark,
    this.currentSpeed = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (routeInfo.steps.isEmpty || currentStepIndex >= routeInfo.steps.length) {
      return const SizedBox.shrink();
    }

    final step = routeInfo.steps[currentStepIndex];

    final distanceText = distanceToNextStep > 1000
        ? (distanceToNextStep / 1000).toStringAsFixed(1)
        : distanceToNextStep.round().toString();
    final distanceUnit = distanceToNextStep > 1000 ? 'km' : 'm';

    return Hero(
      tag: 'navigationGuidance',
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(8)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: context.w(20),
              offset: Offset(0, context.h(10)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.r(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(context.w(20)),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(context.r(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(12)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      color: Colors.blueAccent,
                      size: context.sp(32),
                    ),
                  ),
                  SizedBox(width: context.w(20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$distanceText $distanceUnit',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (currentSpeed > 0) ...[
                              SizedBox(width: context.w(16)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(4),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(context.r(12)),
                                ),
                                child: Text(
                                  '${currentSpeed.round()} km/h',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: context.sp(12),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: context.h(4)),
                        Text(
                          step.instruction,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: context.sp(22),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RouteInfoPanel extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isNavigating;
  final TravelMode travelMode;
  final bool isDark;
  final bool isFetchingRoute;
  final VoidCallback onClear;
  final Function(TravelMode) onModeSelect;
  final List<RouteAlternative>? alternatives;
  final int selectedAlternativeIndex;
  final VoidCallback? onShowAlternatives;

  const RouteInfoPanel({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    if (!routeInfo.hasRoute) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(
          left: context.w(16),
          right: context.w(16),
          bottom: MediaQuery.of(context).padding.bottom + context.h(16)),
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
        borderRadius:
            BorderRadius.circular(isNavigating ? context.r(16) : context.r(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isNavigating ? context.w(16) : context.w(24),
                vertical: isNavigating ? context.h(12) : context.h(20)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(
                  isNavigating ? context.r(16) : context.r(28)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: isNavigating
                ? _buildCompactDrivingMode(context)
                : _buildDefaultMode(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultMode(BuildContext context) {
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
                    _modeChip(context, TravelMode.driving,
                        Icons.directions_car_rounded),
                    SizedBox(width: context.w(6)),
                    _modeChip(context, TravelMode.motorcycle,
                        Icons.motorcycle_rounded),
                    SizedBox(width: context.w(6)),
                    _modeChip(context, TravelMode.bicycle,
                        Icons.directions_bike_rounded),
                    SizedBox(width: context.w(6)),
                    _modeChip(context, TravelMode.foot,
                        Icons.directions_walk_rounded),
                  ],
                ),
              ),
            ),
            _closeButton(context),
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

  Widget _buildCompactDrivingMode(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForMode(travelMode),
            color: Colors.blueAccent,
            size: context.sp(24),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routeInfo.etaText,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                routeInfo.distanceText,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(BuildContext context, TravelMode mode, IconData icon) {
    final isSelected = travelMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNavigating ? null : () => onModeSelect(mode),
        borderRadius: BorderRadius.circular(context.r(12)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Icon(
            icon,
            size: context.sp(20),
            color: isSelected
                ? Colors.blueAccent
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
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

  Widget _closeButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(20)),
        onTap: onClear,
        child: Container(
          padding: EdgeInsets.all(context.w(8)),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: context.sp(20),
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
