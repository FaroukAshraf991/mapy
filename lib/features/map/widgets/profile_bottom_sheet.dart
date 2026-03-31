import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/profile/screens/edit_profile_sheet.dart';
import 'package:mapy/features/settings/screens/settings_screen.dart';

class ProfileBottomSheet extends StatefulWidget {
  final String userName;
  final VoidCallback? onProfileUpdate;

  const ProfileBottomSheet({
    super.key,
    required this.userName,
    this.onProfileUpdate,
  });

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  void _navigateToEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileScreen(),
    ).then((_) {
      widget.onProfileUpdate?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      margin:
          EdgeInsets.fromLTRB(context.w(12), 0, context.w(12), context.h(12)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.r(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: context.w(20),
            spreadRadius: context.w(5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(40),
            height: context.h(4),
            margin: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(context.r(2)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.w(20), context.h(8), context.w(20), context.h(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(isDark),
                SizedBox(height: context.h(16)),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: context.h(6)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToEditProfile,
                    borderRadius: BorderRadius.circular(context.r(20)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(16), vertical: context.h(8)),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(context.r(20)),
                      ),
                      child: Text(
                        'Manage your Account',
                        style: TextStyle(
                          fontSize: context.sp(13),
                          color: textColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          _buildMenuItem(
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
          SizedBox(height: context.h(8)),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(8)),
            child: _buildMenuItem(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: Colors.redAccent.withValues(alpha: 0.8),
              isDark: isDark,
              onTap: () async {
                await AuthService.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
          SizedBox(height: context.h(8)),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Hero(
      tag: 'profileAvatar',
      child: GestureDetector(
        onTap: _navigateToEditProfile,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: context.r(28),
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: context.sp(22),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppConstants.darkBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? (isDark ? Colors.white70 : Colors.black54);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(24)),
      leading: Icon(icon, color: iconColor, size: context.sp(24)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(15),
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
