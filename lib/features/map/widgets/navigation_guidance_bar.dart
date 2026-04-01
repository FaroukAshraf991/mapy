import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';

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
