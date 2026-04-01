import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/services/search_history_service.dart';
import 'package:mapy/services/voice_navigation_service.dart';
import 'package:mapy/blocs/theme/theme_cubit.dart';
import 'package:mapy/features/settings/widgets/section_header.dart';
import 'package:mapy/features/settings/widgets/settings_card.dart';
import 'package:mapy/features/settings/widgets/settings_dropdown_tile.dart';
import 'package:mapy/features/map/screens/trip_history_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  String _units = 'km', _defaultStyle = 'street', _appVersion = '';
  bool _voiceNavigationEnabled = true;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _units = prefs.getString('distance_units') ?? 'km';
      _defaultStyle = prefs.getString('default_map_style') ?? 'street';
      _appVersion = packageInfo.version;
      _voiceNavigationEnabled =
          prefs.getBool('voice_navigation_enabled') ?? true;
    });
  }
  Future<void> _updateSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    setState(() {
      if (key == 'distance_units') _units = value;
      if (key == 'default_map_style') _defaultStyle = value;
    });
  }
  Future<void> _clearHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) await SearchHistoryService.clearHistory(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Search history cleared')));
  }
  String _getThemeValue(ThemeMode mode) => mode == ThemeMode.system
      ? 'system'
      : (mode == ThemeMode.dark ? 'dark' : 'light');
  IconData _getThemeIcon(ThemeMode mode) => mode == ThemeMode.system
      ? Icons.brightness_auto_rounded
      : (mode == ThemeMode.dark
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded);
  Color _getThemeColor(ThemeMode mode) => mode == ThemeMode.system
      ? Colors.purple
      : (mode == ThemeMode.dark ? Colors.blueAccent : Colors.orange);
  String _getThemeLabel(ThemeMode mode) => mode == ThemeMode.system
      ? 'Follow system'
      : (mode == ThemeMode.dark ? 'Dark mode' : 'Light mode');
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : Colors.white;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
          title: Text('Settings',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: context.sp(18))),
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true),
      body: ListView(padding: EdgeInsets.all(context.w(16)), children: [
        SectionHeader(title: 'Appearance', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, currentMode) => ListTile(
                      leading: Icon(_getThemeIcon(currentMode),
                          color: _getThemeColor(currentMode),
                          size: context.sp(24)),
                      title: Text('Theme',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: context.sp(15))),
                      subtitle: Text(_getThemeLabel(currentMode),
                          style: TextStyle(fontSize: context.sp(13))),
                      trailing: DropdownButton<String>(
                          value: _getThemeValue(currentMode),
                          underline: const SizedBox(),
                          onChanged: (value) {
                            if (value != null)
                              context.read<ThemeCubit>().setThemeMode(value);
                          },
                          items: [
                            DropdownMenuItem(
                                value: 'light',
                                child: Text('Light',
                                    style:
                                        TextStyle(fontSize: context.sp(14)))),
                            DropdownMenuItem(
                                value: 'dark',
                                child: Text('Dark',
                                    style:
                                        TextStyle(fontSize: context.sp(14)))),
                            DropdownMenuItem(
                                value: 'system',
                                child: Text('System',
                                    style:
                                        TextStyle(fontSize: context.sp(14)))),
                          ]),
                    ))),
        SizedBox(height: context.h(24)),
        SectionHeader(title: 'Navigation', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: SwitchListTile(
              title: Text('Voice Navigation',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: context.sp(15))),
              subtitle: Text('Voice guidance during navigation',
                  style: TextStyle(fontSize: context.sp(13))),
              secondary: Icon(Icons.record_voice_over_rounded,
                  color:
                      _voiceNavigationEnabled ? Colors.blueAccent : Colors.grey,
                  size: context.sp(24)),
              value: _voiceNavigationEnabled,
              onChanged: (bool value) async {
                await VoiceNavigationService.setEnabled(value);
                setState(() => _voiceNavigationEnabled = value);
              },
            )),
        SizedBox(height: context.h(24)),
        SectionHeader(title: 'Map Display', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: Column(children: [
              SettingsDropdownTile(
                  title: 'Distance Units',
                  subtitle: 'Units for travel distance and scale',
                  value: _units,
                  items: const {'km': 'Kilometers (km)', 'mi': 'Miles (mi)'},
                  onChanged: (val) => _updateSetting('distance_units', val!)),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.black12),
              SettingsDropdownTile(
                  title: 'Default Map Style',
                  subtitle: 'Style used when the app starts',
                  value: _defaultStyle,
                  items: const {
                    'street': 'Standard Street',
                    'satellite': 'Satellite View',
                    'terrain': 'Terrain Map'
                  },
                  onChanged: (val) =>
                      _updateSetting('default_map_style', val!)),
            ])),
        SizedBox(height: context.h(24)),
        SectionHeader(title: 'Favorites', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: Column(children: [
              ListTile(
                  leading: Icon(Icons.home_rounded,
                      color: Colors.blue, size: context.sp(24)),
                  title: Text('Home Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: context.sp(15))),
                  subtitle: Text('Set your home address',
                      style: TextStyle(fontSize: context.sp(13))),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : Colors.black38),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set home from map')))),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.black12),
              ListTile(
                  leading: Icon(Icons.work_rounded,
                      color: Colors.orange, size: context.sp(24)),
                  title: Text('Work Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: context.sp(15))),
                  subtitle: Text('Set your work address',
                      style: TextStyle(fontSize: context.sp(13))),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : Colors.black38),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set work from map')))),
            ])),
        SizedBox(height: context.h(24)),
        SectionHeader(title: 'Activity', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: ListTile(
                leading: Icon(Icons.history_rounded,
                    color: Colors.blueAccent, size: context.sp(24)),
                title: Text('Trip History',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: context.sp(15))),
                subtitle: Text('View your past trips',
                    style: TextStyle(fontSize: context.sp(13))),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black38),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TripHistoryScreen())))),
        SizedBox(height: context.h(24)),
        SectionHeader(title: 'Privacy', isDark: isDark),
        SettingsCard(
            color: cardColor,
            child: ListTile(
              title: Text('Clear Search History',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                      fontSize: context.sp(15))),
              subtitle: Text('Wipe all recent places and searches',
                  style: TextStyle(fontSize: context.sp(13))),
              leading: Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: context.sp(24)),
              onTap: () => _showConfirmationDialog(
                  title: 'Clear History?',
                  content:
                      'This will permanently delete all your recent searches.',
                  onConfirm: _clearHistory),
            )),
        SizedBox(height: context.h(40)),
        Center(
            child: Text('Mapy v$_appVersion\nProfessional Navigation',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: context.sp(12)))),
        SizedBox(height: context.h(20)),
      ]),
    );
  }
  void _showConfirmationDialog(
      {required String title,
      required String content,
      required VoidCallback onConfirm}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title, style: TextStyle(fontSize: context.sp(16))),
              content:
                  Text(content, style: TextStyle(fontSize: context.sp(14))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: context.sp(14)))),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Text('Confirm',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: context.sp(14)))),
              ],
            ));
  }
}
