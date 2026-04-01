import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/services/location_share_service.dart';
/// Bottom sheet showing actions for a saved Home or Work location.
///
/// Provides options to navigate to, change, or clear the location.
class LocationActionSheet extends StatelessWidget {
  final String type;
  final double latitude;
  final double longitude;
  final VoidCallback onNavigate;
  final VoidCallback onChange;
  final VoidCallback onClear;
  const LocationActionSheet({
    super.key,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.onNavigate,
    required this.onChange,
    required this.onClear,
  });
  static void show({
    required BuildContext context,
    required String type,
    required double latitude,
    required double longitude,
    required VoidCallback onNavigate,
    required VoidCallback onChange,
    required VoidCallback onClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(24))),
      ),
      builder: (_) => LocationActionSheet(
        type: type,
        latitude: latitude,
        longitude: longitude,
        onNavigate: onNavigate,
        onChange: onChange,
        onClear: onClear,
      ),
    );
  }
  bool get _isHome => type == 'home';
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(context, isDark),
            _buildHeader(context, textColor),
            SizedBox(height: context.h(8)),
            _buildCoords(context, textColor),
            SizedBox(height: context.h(16)),
            Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
            _ActionTile(
              icon: Icons.share_rounded,
              iconColor: Colors.blueAccent,
              label: 'Share location',
              textColor: textColor,
              onTap: () {
                Navigator.pop(context);
                LocationShareService.shareLocation(
                  latitude: latitude,
                  longitude: longitude,
                  placeName: _isHome ? 'Home' : 'Work',
                );
              },
            ),
            _ActionTile(
              icon: Icons.navigation_rounded,
              iconColor: Colors.blueAccent,
              label: 'Go to ${_isHome ? "Home" : "Work"}',
              textColor: textColor,
              onTap: () {
                Navigator.pop(context);
                onNavigate();
              },
            ),
            _ActionTile(
              icon: Icons.edit_location_alt_rounded,
              iconColor: Colors.green,
              label: 'Change location',
              textColor: textColor,
              onTap: () {
                Navigator.pop(context);
                onChange();
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.redAccent,
              label: 'Clear ${_isHome ? "Home" : "Work"}',
              textColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                onClear();
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHandle(BuildContext context, bool isDark) {
    return Container(
      width: context.w(40),
      height: context.h(4),
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(context.r(2)),
      ),
    );
  }
  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(24)),
      child: Row(children: [
        Icon(
          _isHome ? Icons.home_rounded : Icons.work_rounded,
          color: _isHome ? Colors.blue : Colors.orange,
          size: context.sp(28),
        ),
        SizedBox(width: context.w(12)),
        Text(
          _isHome ? 'Home' : 'Work',
          style: TextStyle(
            fontSize: context.sp(20),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ]),
    );
  }
  Widget _buildCoords(BuildContext context, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(24)),
      child: Text(
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
        style: TextStyle(
          fontSize: context.sp(13),
          color: textColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(24), vertical: context.h(4)),
      leading: Container(
        width: context.w(44),
        height: context.h(44),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: context.sp(22)),
      ),
      title: Text(
        label,
        style: TextStyle(
            fontSize: context.sp(16),
            fontWeight: FontWeight.w600,
            color: textColor),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: context.sp(14),
        color: textColor.withValues(alpha: 0.3),
      ),
      onTap: onTap,
    );
  }
}
