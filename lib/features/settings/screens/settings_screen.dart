import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapy/main.dart';
import 'package:mapy/core/constants/app_constants.dart';

/// A professional settings screen for managing app-wide preferences.
/// Handles theme, units, map styles, and history management with full persistence.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _units = 'km';
  String _defaultStyle = 'street';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads all persistent user preferences from SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _units = prefs.getString('distance_units') ?? 'km';
      _defaultStyle = prefs.getString('default_map_style') ?? 'street';
    });
  }

  /// Persists a specific setting and updates the local state.
  Future<void> _updateSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    setState(() {
      if (key == 'distance_units') _units = value;
      if (key == 'default_map_style') _defaultStyle = value;
    });
  }

  /// Clears the local search history.
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches'); // Assuming this is the key
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : Colors.white;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          _buildSectionHeader('Appearance', isDark),
          _buildSettingsCard(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final isDarkTheme = currentMode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Use a dark theme for the entire app'),
                  secondary: Icon(
                    isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDarkTheme ? Colors.blueAccent : Colors.orange,
                  ),
                  value: isDarkTheme,
                  onChanged: (bool value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDarkTheme', value);
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
            color: cardColor,
          ),

          const SizedBox(height: 24),

          // ── Map Preferences ───────────────────────────────────────────────
          _buildSectionHeader('Map Display', isDark),
          _buildSettingsCard(
            color: cardColor,
            child: Column(
              children: [
                _buildDropdownTile(
                  title: 'Distance Units',
                  subtitle: 'Units for travel distance and scale',
                  value: _units,
                  items: const {'km': 'Kilometers (km)', 'mi': 'Miles (mi)'},
                  onChanged: (val) => _updateSetting('distance_units', val!),
                ),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                _buildDropdownTile(
                  title: 'Default Map Style',
                  subtitle: 'Style used when the app starts',
                  value: _defaultStyle,
                  items: const {
                    'street': 'Standard Street',
                    'satellite': 'Satellite View',
                    'terrain': 'Terrain Map'
                  },
                  onChanged: (val) => _updateSetting('default_map_style', val!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Privacy & Data ────────────────────────────────────────────────
          _buildSectionHeader('Privacy', isDark),
          _buildSettingsCard(
            color: cardColor,
            child: ListTile(
              title: const Text('Clear Search History', 
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.redAccent)),
              subtitle: const Text('Wipe all recent places and searches'),
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onTap: () => _showConfirmationDialog(
                title: 'Clear History?',
                content: 'This will permanently delete all your recent searches.',
                onConfirm: _clearHistory,
              ),
            ),
          ),

          const SizedBox(height: 40),
          
          // ── Version Info ─────────────────────────────────────────────────
          Center(
            child: Text(
              'Mapy v1.2.0\nProfessional Navigation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        onChanged: onChanged,
        items: items.entries.map((e) {
          return DropdownMenuItem(value: e.key, child: Text(e.value));
        }).toList(),
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
