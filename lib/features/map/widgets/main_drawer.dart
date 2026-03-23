import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapy/main.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/services/profile_service.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/profile/screens/edit_profile_screen.dart';

class MainDrawer extends StatefulWidget {
  final String userName;
  final VoidCallback? onProfileUpdate;

  const MainDrawer({
    super.key,
    required this.userName,
    this.onProfileUpdate,
  });

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _avatarUrl = profile.avatarUrl);
  }

  void _navigateToEditProfile() {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((_) {
      _loadAvatar();
      widget.onProfileUpdate?.call(); // Signal parent (MainMapScreen) to reload
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;

    return Drawer(
      backgroundColor: primaryBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.blue.shade50.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _navigateToEditProfile,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white,
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppConstants.darkBackground,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _navigateToEditProfile,
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueAccent.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(
                  color: isDark
                      ? Colors.white24
                      : Colors.grey.shade200,
                  thickness: 1.5),
            ),

            _buildDrawerItem(
              context: context,
              icon: Icons.history_rounded,
              title: 'Recent Places',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Open "Where to?" to see recent places!')));
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')));
              },
            ),


            const Spacer(),

            // ── Dark Mode Toggle ────────────────────────────────────────────
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isDarkTheme = currentMode == ThemeMode.dark;
                return Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDarkTheme
                            ? Colors.white12
                            : Colors.grey.shade200,
                        width: 1.5),
                  ),
                  child: SwitchListTile(
                    title: Text('Dark Mode',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkTheme
                                ? Colors.white
                                : Colors.black87)),
                    secondary: Icon(
                        isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkTheme
                            ? Colors.blueAccent
                            : Colors.orange),
                    value: isDarkTheme,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onChanged: (bool value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isDarkTheme', value);
                      themeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                );
              },
            ),

            // ── Logout Button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Logout',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      leading: Icon(icon,
          color: isDark ? Colors.white70 : Colors.black54, size: 28),
      title: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hoverColor: isDark ? Colors.white10 : Colors.grey.shade100,
      onTap: onTap,
    );
  }
}
