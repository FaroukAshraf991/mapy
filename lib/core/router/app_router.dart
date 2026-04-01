import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_cubit.dart';
import 'app_routes.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/update_password_screen.dart';
import '../../features/auth/screens/add_account_screen.dart';
import '../../features/map/screens/main_map_screen.dart';
import '../../features/map/screens/next_where_to_screen.dart';
import '../../features/map/screens/pick_location_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Create the GoRouter instance with auth state integration
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // Use AuthCubit stream to trigger redirect re-evaluation
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),

    // Top-level redirect: runs before any navigation
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authCubit.state.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.updatePassword;

      // If not authenticated and trying to access protected route -> redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on auth route -> redirect to map
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.map;
      }

      // No redirect needed
      return null;
    },

    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        name: 'update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

      // Main app routes (protected)
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userName = extra?['userName'] as String? ??
              authCubit.state.userName ??
              'User';
          return MainMapScreen(userName: userName);
        },
        routes: [
          GoRoute(
            path: 'search',
            name: 'search',
            builder: (context, state) => const NextWhereToScreen(),
          ),
          GoRoute(
            path: 'pick-location/:title',
            name: 'pick-location',
            builder: (context, state) {
              final title = Uri.decodeComponent(
                  state.pathParameters['title'] ?? 'Pick Location');
              return PickLocationScreen(title: title);
            },
          ),
        ],
      ),

      // Settings route (protected)
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Add account — accessible while already authenticated.
      // Intentionally NOT in isAuthRoute so GoRouter won't redirect away.
      GoRoute(
        path: AppRoutes.addAccount,
        name: 'add-account',
        builder: (context, state) => const AddAccountScreen(),
      ),
    ],
  );
}

/// Helper class to convert a Bloc stream to a Listenable
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
