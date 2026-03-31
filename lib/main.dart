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
  final results = await Future.wait([
    _initSupabase(supabaseUrl),
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[1] as SharedPreferences;
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
}

/// Helper to safely initialize Supabase during startup
Future<void> _initSupabase(String url) async {
  // Don't attempt initialization with empty credentials
  if (url.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    debugPrint('Skipping Supabase initialization - credentials missing');
    return;
  }

  try {
    await Supabase.initialize(
      url: url,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
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
