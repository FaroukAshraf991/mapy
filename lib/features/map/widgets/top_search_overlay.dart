import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/models/place_result.dart';

/// Top overlay containing the greeting, search bar, and shortcuts.
class TopSearchOverlay extends StatelessWidget {
  final String userName;
  final String greeting;
  final bool isDark;
  final bool isRouting;
  final bool hasRecents;
  final bool showTopUI;
  final List<PlaceResult> searchHistory;
  final ll.LatLng? homeLocation;
  final ll.LatLng? workLocation;
  final List<Map<String, dynamic>> customPins;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onRecentsTap;
  final VoidCallback onHomeTap;
  final VoidCallback onWorkTap;
  final Function(Map<String, dynamic>) onCustomPinTap;
  final Function(Map<String, dynamic>) onCustomPinLongPress;
  final VoidCallback onAddTap;

  const TopSearchOverlay({
    super.key,
    required this.userName,
    required this.greeting,
    required this.isDark,
    required this.isRouting,
    required this.hasRecents,
    this.showTopUI = true,
    required this.searchHistory,
    required this.homeLocation,
    required this.workLocation,
    required this.customPins,
    required this.onSearchTap,
    required this.onAvatarTap,
    required this.onRecentsTap,
    required this.onHomeTap,
    required this.onWorkTap,
    required this.onCustomPinTap,
    required this.onCustomPinLongPress,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!showTopUI) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: context.topPadding + context.h(12),
      left: context.w(16),
      right: context.w(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGreeting(context),
          MapSearchBar(
            isDark: isDark,
            isRouting: isRouting,
            userName: userName,
            onSearchTap: onSearchTap,
            onAvatarTap: onAvatarTap,
          ),
          SizedBox(height: context.h(12)),
          ShortcutsBar(
            isDark: isDark,
            hasRecents: searchHistory.isNotEmpty,
            hasHome: homeLocation != null,
            hasWork: workLocation != null,
            customPins: customPins,
            onRecentsTap: onRecentsTap,
            onHomeTap: onHomeTap,
            onWorkTap: onWorkTap,
            onCustomPinTap: onCustomPinTap,
            onCustomPinLongPress: onCustomPinLongPress,
            onAddTap: onAddTap,
          ),
          SizedBox(height: context.h(8)),
          _buildGpsDisplay(context),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(20), left: context.w(4)),
      child: Text(
        '$greeting, ${userName.split(' ').first}!',
        style: TextStyle(
          color: Colors.white,
          fontSize: context.sp(28),
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          shadows: [
            Shadow(
                color: Colors.black45,
                blurRadius: context.w(10),
                offset: Offset(0, context.h(2))),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsDisplay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  size: context.sp(16),
                  color: Colors.blueAccent,
                ),
                SizedBox(width: context.w(8)),
                Text(
                  'Tap map to select location',
                  style: TextStyle(
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
