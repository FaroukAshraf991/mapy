import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/widgets/constrained_content_box.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/features/map/widgets/route_directions_header.dart';

/// Top overlay containing the greeting, search bar, POI category tiles, or the
/// active route directions header depending on routing state.
class TopSearchOverlay extends StatefulWidget {
  final String userName;
  final bool isDark;
  final bool isRouting;
  final bool showTopUI;
  final String? destinationName;
  final String? originName;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;
  final Function(String) onCategoryTap;
  final Function(String)? onVoiceResult;
  final VoidCallback onSwapEndpoints;
  final VoidCallback? onOriginTap;
  final VoidCallback? onDestinationTap;

  const TopSearchOverlay({
    super.key,
    required this.userName,
    required this.isDark,
    required this.isRouting,
    this.showTopUI = true,
    this.destinationName,
    this.originName,
    required this.onSearchTap,
    required this.onAvatarTap,
    required this.onCategoryTap,
    this.onVoiceResult,
    required this.onSwapEndpoints,
    this.onOriginTap,
    this.onDestinationTap,
  });

  @override
  State<TopSearchOverlay> createState() => _TopSearchOverlayState();
}

class _TopSearchOverlayState extends State<TopSearchOverlay> {
  late String _greeting;
  Timer? _greetingTimer;

  static String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static Duration _durationUntilNextBoundary() {
    final now = DateTime.now();
    final boundaries = [12, 17];
    for (final b in boundaries) {
      if (now.hour < b) {
        final next = DateTime(now.year, now.month, now.day, b);
        return next.difference(now) + const Duration(seconds: 1);
      }
    }
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now) + const Duration(seconds: 1);
  }

  void _scheduleNextUpdate() {
    _greetingTimer?.cancel();
    _greetingTimer = Timer(_durationUntilNextBoundary(), () {
      if (mounted) {
        setState(() => _greeting = _computeGreeting());
        _scheduleNextUpdate();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _greeting = _computeGreeting();
    _scheduleNextUpdate();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showTopUI) {
      return _buildDirectionsHeader(context);
    }

    return Positioned(
      top: context.topPadding + context.h(12),
      left: 0,
      right: 0,
      child: ConstrainedContentBox(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreeting(context),
              MapSearchBar(
                isDark: widget.isDark,
                isRouting: widget.isRouting,
                userName: widget.userName,
                onSearchTap: widget.onSearchTap,
                onAvatarTap: widget.onAvatarTap,
                onVoiceResult: widget.onVoiceResult,
              ),
              SizedBox(height: context.h(12)),
              _buildPoiCategories(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoiCategories(BuildContext context) {
    final categories = [
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Restaurants', 'query': 'restaurant'},
      {'icon': Icons.local_gas_station_rounded, 'label': 'Gas Stations', 'query': 'gas station'},
      {'icon': Icons.local_parking_rounded, 'label': 'Parking', 'query': 'parking'},
      {'icon': Icons.hotel_rounded, 'label': 'Hotels', 'query': 'hotel'},
      {'icon': Icons.shopping_bag_rounded, 'label': 'Shopping', 'query': 'shopping mall'},
      {'icon': Icons.local_hospital_rounded, 'label': 'Hospitals', 'query': 'hospital'},
    ];

    return SizedBox(
      height: context.h(44),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: context.h(2)),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => widget.onCategoryTap(cat['query'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(14), vertical: context.h(8)),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(context.r(50)),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.07),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: context.w(8),
                    offset: Offset(0, context.h(2)),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'] as IconData,
                      color: widget.isDark ? Colors.white : Colors.black87,
                      size: context.sp(16)),
                  SizedBox(width: context.w(6)),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDirectionsHeader(BuildContext context) {
    final name = widget.destinationName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: context.topPadding + context.h(12),
      left: 0,
      right: 0,
      child: ConstrainedContentBox(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: RouteDirectionsHeader(
            originName: widget.originName ?? 'Your location',
            destinationName: name,
            isDark: widget.isDark,
            onSwapEndpoints: widget.onSwapEndpoints,
            onOriginTap: widget.onOriginTap,
            onDestinationTap: widget.onDestinationTap,
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(20), left: context.w(4)),
      child: Text(
        '$_greeting, ${widget.userName.split(' ').first}!',
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
