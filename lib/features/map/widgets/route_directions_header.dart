import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';

/// Google Maps–style directions header shown during pre-navigation.
/// Origin row and destination row are both tappable to change each endpoint.
class RouteDirectionsHeader extends StatelessWidget {
  final String originName;
  final String destinationName;
  final bool isDark;
  final VoidCallback onSwapEndpoints;
  final VoidCallback? onOriginTap;
  final VoidCallback? onDestinationTap;

  const RouteDirectionsHeader({
    super.key,
    this.originName = AppStrings.yourLocation,
    required this.destinationName,
    required this.isDark,
    required this.onSwapEndpoints,
    this.onOriginTap,
    this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E2326) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OriginRow(
            originName: originName,
            isDark: isDark,
            onTap: onOriginTap,
          ),
          _DotsConnector(isDark: isDark),
          _DestinationRow(
            destinationName: destinationName,
            isDark: isDark,
            onTap: onDestinationTap,
            onSwap: onSwapEndpoints,
          ),
        ],
      ),
    );
  }
}

// ─── Origin row ───────────────────────────────────────────────────────────────

class _OriginRow extends StatelessWidget {
  final String originName;
  final bool isDark;
  final VoidCallback? onTap;

  const _OriginRow({
    required this.originName,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(16))),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(14), vertical: context.h(10)),
        child: Row(
          children: [
            _buildOriginDot(context),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Text(
                originName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            Icon(
              Icons.more_horiz_rounded,
              size: context.sp(18),
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginDot(BuildContext context) => Container(
        width: context.sp(18),
        height: context.sp(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withValues(alpha: 0.15),
          border: Border.all(color: Colors.blueAccent, width: 2.0),
        ),
        child: Center(
          child: Container(
            width: context.sp(7),
            height: context.sp(7),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.blueAccent),
          ),
        ),
      );
}

// ─── Dots connector ───────────────────────────────────────────────────────────

class _DotsConnector extends StatelessWidget {
  final bool isDark;
  const _DotsConnector({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dotColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.20);

    return Row(
      children: [
        SizedBox(width: context.w(21)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(context, dotColor),
            SizedBox(height: context.h(2)),
            _dot(context, dotColor),
            SizedBox(height: context.h(2)),
            _dot(context, dotColor),
          ],
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context, Color color) => Container(
        width: context.w(4),
        height: context.h(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Destination row ──────────────────────────────────────────────────────────

class _DestinationRow extends StatelessWidget {
  final String destinationName;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback onSwap;

  const _DestinationRow({
    required this.destinationName,
    required this.isDark,
    required this.onTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(context.r(16))),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(14), vertical: context.h(10)),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Colors.redAccent.shade100,
              size: context.sp(18),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Text(
                destinationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSwap,
              child: Icon(
                Icons.swap_vert_rounded,
                size: context.sp(18),
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
