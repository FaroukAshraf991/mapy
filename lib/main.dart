import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/map/screens/main_map_screen.dart';

// Global single source of truth for app theme
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize massive Cloud Backend Database
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // Check for an existing session to skip the login screen
  final session = Supabase.instance.client.auth.currentSession;
  Widget homeScreen;
  if (session != null) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? 'User';
    homeScreen = MainMapScreen(userName: userName);
  } else {
    homeScreen = const LoginScreen();
  }

  runApp(MapyApp(homeScreen: homeScreen));
}

class MapyApp extends StatelessWidget {
  final Widget homeScreen;
  const MapyApp({super.key, required this.homeScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'Mapy',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          themeMode: currentMode,
          home: homeScreen,
        );
      },
    );
  }
}
