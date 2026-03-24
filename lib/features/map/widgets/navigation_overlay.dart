import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';

/// Top bar overlay showing turn-by-turn guidance.
class NavigationGuidanceBar extends StatelessWidget {
  final RouteInfo routeInfo;
  final int currentStepIndex;
  final ValueListenable<double> distanceToNextStepNotifier;
  final bool isDark;

  const NavigationGuidanceBar({
    super.key,
    required this.routeInfo,
    required this.currentStepIndex,
    required this.distanceToNextStepNotifier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (routeInfo.steps.isEmpty || currentStepIndex >= routeInfo.steps.length) {
      return const SizedBox.shrink();
    }
    
    final step = routeInfo.steps[currentStepIndex];

    return ValueListenableBuilder<double>(
      valueListenable: distanceToNextStepNotifier,
      builder: (context, distanceToNextStep, child) {
        final distanceText = distanceToNextStep > 1000 
            ? (distanceToNextStep / 1000).toStringAsFixed(1)
            : distanceToNextStep.round().toString();
        final distanceUnit = distanceToNextStep > 1000 ? 'km' : 'm';

        return Hero(
          tag: 'navigationGuidance',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.6) 
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          step.icon,
                          color: Colors.blueAccent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  distanceText,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueAccent,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distanceUnit,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              step.instruction,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 0.2,
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
      },
    );
  }
}

/// Bottom panel showing route metadata and travel mode selectors.
class RouteInfoPanel extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isNavigating;
  final TravelMode travelMode;
  final bool isDark;
  final VoidCallback onClear;
  final Function(TravelMode) onModeSelect;

  const RouteInfoPanel({
    super.key,
    required this.routeInfo,
    required this.isNavigating,
    required this.travelMode,
    required this.isDark,
    required this.onClear,
    required this.onModeSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (!routeInfo.hasRoute) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (!isNavigating) ...[
                          _modeChip(TravelMode.driving, Icons.directions_car_rounded),
                          const SizedBox(width: 6),
                          _modeChip(TravelMode.motorcycle, Icons.motorcycle_rounded),
                          const SizedBox(width: 6),
                          _modeChip(TravelMode.bicycle, Icons.directions_bike_rounded),
                          const SizedBox(width: 6),
                          _modeChip(TravelMode.foot, Icons.directions_walk_rounded),
                        ] else ...[
                          _modeChip(travelMode, _getIconForMode(travelMode)),
                        ],
                      ],
                    ),
                    if (!isNavigating) _closeButton(),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNavigating)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NAVIGATING',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            MapInfoChip(
                              icon: Icons.timer_outlined,
                              color: Colors.blue,
                              label: routeInfo.etaText, 
                              isDark: isDark,
                            ),
                            const SizedBox(width: 16),
                            MapInfoChip(
                              icon: Icons.straighten_rounded,
                              color: Colors.orange,
                              label: routeInfo.distanceText, 
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(TravelMode mode, IconData icon) {
    final isSelected = travelMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNavigating ? null : () => onModeSelect(mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.purple : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }


  IconData _getIconForMode(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving: return Icons.directions_car_rounded;
      case TravelMode.motorcycle: return Icons.motorcycle_rounded;
      case TravelMode.bicycle: return Icons.directions_bike_rounded;
      case TravelMode.foot: return Icons.directions_walk_rounded;
    }
  }

  Widget _closeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onClear,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
