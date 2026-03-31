import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/route_info.dart';

class RouteAlternativesSheet extends StatelessWidget {
  final List<RouteAlternative> alternatives;
  final int selectedIndex;
  final bool isDark;
  final Function(int) onSelect;

  const RouteAlternativesSheet({
    super.key,
    required this.alternatives,
    required this.selectedIndex,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(24)),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.modalBackground : Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(24))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(24)),
            child: Text('Route Options',
                style: TextStyle(
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          SizedBox(height: context.h(16)),
          ...alternatives.asMap().entries.map((entry) {
            final idx = entry.key;
            final alt = entry.value;
            final isSelected = idx == selectedIndex;
            return _buildRouteOption(context, idx, alt, isSelected);
          }),
          SizedBox(height: context.h(8)),
        ],
      ),
    );
  }

  Widget _buildRouteOption(
      BuildContext context, int index, RouteAlternative alt, bool isSelected) {
    Color routeColor;
    IconData routeIcon;
    if (index == 0) {
      routeColor = Colors.blue;
      routeIcon = Icons.speed_rounded;
    } else if (index == 1) {
      routeColor = Colors.green;
      routeIcon = Icons.route_rounded;
    } else {
      routeColor = Colors.orange;
      routeIcon = Icons.alt_route_rounded;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelect(index);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? routeColor.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(16)),
          border: Border.all(
            color: isSelected ? routeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.r(14)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(10)),
                    decoration: BoxDecoration(
                      color: routeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(routeIcon,
                        color: routeColor, size: context.sp(24)),
                  ),
                  SizedBox(width: context.w(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alt.name,
                            style: TextStyle(
                                fontSize: context.sp(16),
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87)),
                        SizedBox(height: context.h(4)),
                        Text(
                          '${alt.routeInfo.distanceText} • ${alt.routeInfo.etaText}',
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: routeColor, size: context.sp(24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
