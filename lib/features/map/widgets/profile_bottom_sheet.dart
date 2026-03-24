import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/services/profile_service.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/profile/screens/edit_profile_screen.dart';
/*
### 5. Architecture & Auth Cleanup 🛠️
- **Unified Auth Service:** Merged the redundant `lib/database/loginpage_database/auth_service.dart` into the primary `lib/features/auth/services/auth_service.dart`.
- **Feature Parity:** Ported `dateOfBirth` support to the unified service to ensure registration remains fully functional.
- **Reference Updates:** Updated `LoginScreen` and `RegisterScreen` to point to the new, centralized service.
- **Lint Cleanup:** Resolved architectural conflicts and unused variable warnings, achieving a clean `flutter analyze` report.

## Verification Results

### Routing Logic (geocoding_service.dart)
- [x] OSRM Driving mode (openstreetmap.de)
- [x] OSRM Bicycle mode (openstreetmap.de)
- [x] OSRM Foot mode (openstreetmap.de)

### UI Components (main_map_screen.dart & map_widgets.dart)
- [x] Neon Destination Marker (CustomPainter)
- [x] Glassmorphism Route Card (BackdropFilter)
- [x] Animated Switcher for Greeting/Route Card
- [x] Horizontal Location Chips
- [x] Active Navigation Mode Camera Zoom/Lock
- [x] Navigation UI Overlay (Hide Search Bar/Chips)

### Architecture (AuthService)
- [x] Unified AuthService in `features/`
- [x] `flutter analyze` passed (No issues)
*/
import 'package:mapy/features/settings/screens/settings_screen.dart';

/// A modern, Google Maps-style bottom sheet for user profile and account management.
/// Replaces the legacy side drawer with a sleek, floating-card aesthetic.
class ProfileBottomSheet extends StatefulWidget {
  /// The user's full name for the header.
  final String userName;
  
  /// Callback triggered when a profile update occurs within the sheet.
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
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  /// Refetches the avatar URL from the ProfileService.
  Future<void> _loadAvatar() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _avatarUrl = profile.avatarUrl);
  }

  /// Opens the Edit Profile interface as a draggable bottom sheet.
  void _navigateToEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileScreen(),
    ).then((_) {
      _loadAvatar();
      widget.onProfileUpdate?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      // Floating card effect via margins and rounded corners
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ───────────────────────────────────────────────────
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header (Avatar + Name) ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(isDark),
                const SizedBox(height: 16),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToEditProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Manage your Account',
                        style: TextStyle(
                          fontSize: 13,
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

          // ── Menu Options ─────────────────────────────────────────────────
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
          
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),

          // ── Sign Out ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Builds the large profile avatar for the header.
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
            radius: 28,
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
            backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
            child: _avatarUrl == null
                ? Text(
                    widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppConstants.darkBackground,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Helper to build a standard menu item with an icon and label.
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? (isDark ? Colors.white70 : Colors.black54);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
