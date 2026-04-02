import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// Displays the active route's origin and destination in a card at the top
/// of the map screen, mirroring the Google Maps directions input style.
class RouteDirectionsHeader extends StatelessWidget {
  final String originName;
  final String destinationName;
  final bool isDark;
  final VoidCallback onSwapEndpoints;
  final VoidCallback? onMoreOptions;

  const RouteDirectionsHeader({
    super.key,
    this.originName = 'Your location',
    required this.destinationName,
    required this.isDark,
    required this.onSwapEndpoints,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.80)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOriginRow(context),
                _buildDividerWithDots(context),
                _buildDestinationRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      child: Row(
        children: [
          _buildOriginDot(context),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Text(
              originName,
              style: TextStyle(
                fontSize: context.sp(15),
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
          ),
          _buildMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildDestinationRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Colors.redAccent.shade100,
            size: context.sp(20),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Text(
              destinationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.sp(15),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          _buildSwapButton(context),
        ],
      ),
    );
  }

  Widget _buildDividerWithDots(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: context.w(23)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(context),
            SizedBox(height: context.h(3)),
            _dot(context),
            SizedBox(height: context.h(3)),
            _dot(context),
          ],
        ),
        SizedBox(width: context.w(11)),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context) => Container(
        width: context.w(4),
        height: context.h(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.25),
        ),
      );

  Widget _buildOriginDot(BuildContext context) => Container(
        width: context.w(20),
        height: context.w(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withValues(alpha: 0.15),
          border: Border.all(color: Colors.blueAccent, width: 2.0),
        ),
        child: Center(
          child: Container(
            width: context.w(8),
            height: context.w(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
          ),
        ),
      );

  Widget _buildMoreButton(BuildContext context) => IconButton(
        onPressed: onMoreOptions,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: context.sp(22),
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(),
        tooltip: 'More options',
      );

  Widget _buildSwapButton(BuildContext context) => IconButton(
        onPressed: () {
          debugPrint('🔄 Swap button pressed in RouteDirectionsHeader');
          onSwapEndpoints();
        },
        icon: Icon(
          Icons.swap_vert_rounded,
          size: context.sp(22),
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(),
        tooltip: 'Swap endpoints',
      );
}
