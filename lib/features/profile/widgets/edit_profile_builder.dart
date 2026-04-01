import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/profile_menu_item.dart';
import 'package:mapy/features/settings/screens/settings_screen.dart';
import 'package:mapy/services/location_share_service.dart';
import 'package:geolocator/geolocator.dart';

class EditProfileBuilder {
  static Widget buildProfileCard({
    required BuildContext context,
    required bool isDark,
    required String name,
    required VoidCallback onManageAccount,
    required VoidCallback onSettings,
    required VoidCallback onShareLocation,
    required VoidCallback onSignOut,
    required Function(String) showError,
  }) {
    final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.r(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: context.w(24),
            spreadRadius: context.w(4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context, isDark),
          _buildProfileHeader(
              context, isDark, name, textColor, onManageAccount),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          ProfileMenuItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          _buildShareLocationItem(context, isDark, showError),
          SizedBox(height: context.h(4)),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(4)),
            child: ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: const Color(0xFFE05454),
              isDark: isDark,
              onTap: onSignOut,
            ),
          ),
          SizedBox(height: context.h(8)),
        ],
      ),
    );
  }

  static Widget _buildDragHandle(BuildContext context, bool isDark) {
    return Container(
      width: context.w(40),
      height: context.h(4),
      margin: EdgeInsets.symmetric(vertical: context.h(12)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(context.r(2)),
      ),
    );
  }

  static Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    String name,
    Color textColor,
    VoidCallback onManageAccount,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(8),
        context.w(20),
        context.h(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: 'profileAvatar',
            child: CircleAvatar(
              radius: context.r(36),
              backgroundColor: const Color(0xFF5B8DEF),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: context.sp(28),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            name,
            style: TextStyle(
              fontSize: context.sp(20),
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: context.h(10)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onManageAccount,
              borderRadius: BorderRadius.circular(context.r(24)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(20),
                  vertical: context.h(10),
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  borderRadius: BorderRadius.circular(context.r(24)),
                ),
                child: Text(
                  'Manage your Account',
                  style: TextStyle(
                    fontSize: context.sp(14),
                    color: const Color(0xFF5B8DEF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildShareLocationItem(
    BuildContext context,
    bool isDark,
    Function(String) showError,
  ) {
    return ProfileMenuItem(
      icon: Icons.share_location_rounded,
      label: 'Share My Location',
      isDark: isDark,
      onTap: () async {
        Navigator.pop(context);
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            await Geolocator.requestPermission();
          }
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          await LocationShareService.shareLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            placeName: 'My Current Location',
          );
        } catch (e) {
          showError('Unable to share location: $e');
        }
      },
    );
  }
}
