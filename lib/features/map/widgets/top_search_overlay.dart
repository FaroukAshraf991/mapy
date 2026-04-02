import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/features/map/widgets/route_directions_header.dart';
import 'package:mapy/models/place_result.dart';

/// Top overlay containing the greeting, search bar, shortcuts, or the active
/// route directions header depending on routing state.
class TopSearchOverlay extends StatelessWidget {
  final String userName;
  final String greeting;
  final bool isDark;
  final bool isRouting;
  final bool hasRecents;
  final bool showTopUI;
  final String? destinationName;
  final String? originName;
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
  final VoidCallback onSwapEndpoints;

  const TopSearchOverlay({
    super.key,
    required this.userName,
    required this.greeting,
    required this.isDark,
    required this.isRouting,
    required this.hasRecents,
    this.showTopUI = true,
    this.destinationName,
    this.originName,
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
    required this.onSwapEndpoints,
  });

  @override
  Widget build(BuildContext context) {
    if (!showTopUI) {
      return _buildDirectionsHeader(context);
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
        ],
      ),
    );
  }

  Widget _buildDirectionsHeader(BuildContext context) {
    final name = destinationName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: context.topPadding + context.h(12),
      left: context.w(16),
      right: context.w(16),
      child: RouteDirectionsHeader(
        originName: originName ?? 'Your location',
        destinationName: name,
        isDark: isDark,
        onSwapEndpoints: onSwapEndpoints,
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
}
