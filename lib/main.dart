import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/blocs/theme/theme_cubit.dart';
import 'package:mapy/blocs/auth/auth_cubit.dart';
import 'package:mapy/core/router/app_router.dart';
import 'package:mapy/core/middleware/bloc_observer.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Set up BLoC observer for logging
    Bloc.observer = AppBlocObserver();
    // Clean the URL (remove trailing slashes) to prevent Storage SDK errors
    String supabaseUrl = AppConstants.supabaseUrl;
    if (supabaseUrl.endsWith('/')) {
      supabaseUrl = supabaseUrl.substring(0, supabaseUrl.length - 1);
    }
    // Validate credentials before proceeding - show error screen if missing
    if (supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
      runApp(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Missing Supabase Credentials',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please run the app with:\n--dart-define=SUPABASE_URL=...\n--dart-define=SUPABASE_ANON_KEY=...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      return;
    }
    // ── PARALLEL INITIALIZATION ──
    // Initialize Supabase and SharedPreferences concurrently to avoid blocking the UI thread for too long.
    // Timeouts prevent the splash screen from hanging indefinitely on slow/unavailable networks.
    late final SharedPreferences prefs;
    try {
      final results = await Future.wait([
        _initSupabase(supabaseUrl),
        SharedPreferences.getInstance(),
      ]).timeout(const Duration(seconds: 12));
      prefs = results[1] as SharedPreferences;
    } catch (e) {
      debugPrint('Initialization timeout or error: $e');
      // Fallback: Supabase unavailable, use empty prefs
      prefs = await SharedPreferences.getInstance();
    }
    final themeSetting = prefs.getString('theme_setting') ?? 'light';
    ThemeMode initialMode;
    switch (themeSetting) {
      case 'dark':
        initialMode = ThemeMode.dark;
        break;
      case 'system':
        initialMode = ThemeMode.system;
        break;
      default:
        initialMode = ThemeMode.light;
    }
    // Create cubits
    final authCubit = AuthCubit();
    final themeCubit = ThemeCubit()..setTheme(initialMode);
    // Create router with auth cubit integration
    final router = createRouter(authCubit);
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => authCubit),
          BlocProvider(create: (_) => themeCubit),
        ],
        child: MapyApp(router: router),
      ),
    );
  } catch (e, stack) {
    runApp(_StartupErrorApp(error: e.toString(), stack: stack.toString()));
  }
}
/// Helper to safely initialize Supabase during startup.
/// Returns `true` if Supabase was initialized successfully.
Future<bool> _initSupabase(String url) async {
  if (url.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    debugPrint('Skipping Supabase initialization - credentials missing');
    return false;
  }
  try {
    await Supabase.initialize(
      url: url,
      anonKey: AppConstants.supabaseAnonKey,
    );
    return true;
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
    return false;
  }
}
class MapyApp extends StatelessWidget {
  final GoRouter router;
  const MapyApp({super.key, required this.router});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentMode) {
        return MaterialApp.router(
          title: 'Mapy',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
            scaffoldBackgroundColor: AppConstants.darkSurface,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: currentMode,
        );
      },
    );
  }
}
class _StartupErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const _StartupErrorApp({required this.error, required this.stack});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF2C2C2C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Startup Failed',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Stack Trace',
                      style: TextStyle(color: Colors.white70)),
                  children: [
                    SelectableText(
                      stack,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Restart the app. If this persists, check your network '
                  'connection and Supabase credentials.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
