import 'package:flutter/material.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';

/// Top bar overlay showing turn-by-turn guidance.
class NavigationGuidanceBar extends StatelessWidget {
  final RouteInfo routeInfo;
  final int currentStepIndex;
  final double distanceToNextStep;
  final bool isDark;

  const NavigationGuidanceBar({
    super.key,
    required this.routeInfo,
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (routeInfo.steps.isEmpty || currentStepIndex >= routeInfo.steps.length) {
      return const SizedBox.shrink();
    }
    
    final step = routeInfo.steps[currentStepIndex];
    final distanceText = distanceToNextStep > 1000 
        ? '${(distanceToNextStep / 1000).toStringAsFixed(1)} km'
        : '${distanceToNextStep.round()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  step.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 12,
            shadowColor: Colors.black38,
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _modeChip(TravelMode.driving, Icons.directions_car_rounded),
                          const SizedBox(width: 4),
                          _modeChip(TravelMode.motorcycle, Icons.motorcycle_rounded),
                          const SizedBox(width: 4),
                          _modeChip(TravelMode.bicycle, Icons.directions_bike_rounded),
                          const SizedBox(width: 4),
                          _modeChip(TravelMode.foot, Icons.directions_walk_rounded),
                        ],
                      ),
                      _closeButton(),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isNavigating)
                            const Text(
                              'NAVIGATING...',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          Row(
                            children: [
                              MapInfoChip(
                                icon: Icons.timer_outlined,
                                color: Colors.blue,
                                label: routeInfo.etaText, 
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
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
        ],
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
