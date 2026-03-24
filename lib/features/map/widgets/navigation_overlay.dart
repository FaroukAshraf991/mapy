import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mapy/features/map/models/route_info.dart';
 import 'package:mapy/services/geocoding_service.dart';

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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.65) 
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Direction Icon with Glow
                      Container(
                        padding: const EdgeInsets.all(12),
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
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Instructions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$distanceText $distanceUnit',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.instruction,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 22,
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
      margin: EdgeInsets.only(
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 16
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.7) 
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
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
                    Expanded(
                      child: Column(
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
                              Text(
                                routeInfo.etaText,
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  routeInfo.distanceText,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fastest route via Main St',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blueAccent : (isDark ? Colors.white54 : Colors.black45),
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
