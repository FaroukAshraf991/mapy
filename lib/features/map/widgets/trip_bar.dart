import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// The "Where would you like to go?" floating bar with START / PREVIEW / EXIT buttons.
class TripBar extends StatelessWidget {
  final bool hasRoute;
  final bool isNavigating;
  final bool isDark;
  final bool isSwapped;
  final VoidCallback onTap;
  final VoidCallback onStartNavigation;
  final VoidCallback onExitNavigation;
  final VoidCallback? onPreview;

  const TripBar({
    super.key,
    required this.hasRoute,
    required this.isNavigating,
    required this.isDark,
    this.isSwapped = false,
    required this.onTap,
    required this.onStartNavigation,
    required this.onExitNavigation,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('trip_bar_${hasRoute}_$isNavigating'),
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
        borderRadius: BorderRadius.circular(context.r(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(context.r(28)),
            child: InkWell(
              onTap: (isNavigating || hasRoute) ? null : onTap,
              borderRadius: BorderRadius.circular(context.r(28)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(20), vertical: context.h(18)),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(context.r(28)),
                ),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildText(context)),
        if (hasRoute && !isNavigating && !isSwapped) _buildStartButton(context),
        if (hasRoute && !isNavigating && isSwapped)
          _buildPreviewButton(context),
        if (isNavigating) _buildExitButton(context),
      ],
    );
  }

  Widget _buildText(BuildContext context) {
    final statusLabel = isNavigating
        ? 'ACTIVE GUIDANCE'
        : (hasRoute ? 'ESTIMATED TRAVEL TIME' : 'READY TO GO');
    final statusColor = isNavigating
        ? Colors.blueAccent
        : (isDark ? Colors.white38 : Colors.black38);
    final subtitle = isNavigating
        ? 'Drive safely'
        : (hasRoute ? 'Route calculated' : 'Where would you like to go?');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: context.sp(10),
            fontWeight: FontWeight.w900,
            color: statusColor,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: context.sp(20),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onStartNavigation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(24), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(18)),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      icon: Icon(Icons.navigation_rounded, size: context.sp(22)),
      label: Text(
        'START',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: context.sp(16),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPreviewButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPreview,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(24), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(18)),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      icon: Icon(Icons.compare_arrows_rounded, size: context.sp(22)),
      label: Text(
        'PREVIEW',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: context.sp(16),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildExitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onExitNavigation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(24), vertical: context.h(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(18)),
        ),
        elevation: 8,
        shadowColor: Colors.redAccent.withValues(alpha: 0.4),
      ),
      child: Text(
        'EXIT',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: context.sp(16),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
