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
const _defaultTransitionDuration = Duration(milliseconds: 350);
const _defaultReverseTransitionDuration = Duration(milliseconds: 300);
Widget _smoothPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final secondaryCurvedAnimation = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeInCubic,
    reverseCurve: Curves.easeOutCubic,
  );
  return FadeTransition(
    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    ),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.05),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0)
            .animate(secondaryCurvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.0, -0.03),
          ).animate(secondaryCurvedAnimation),
          child: child,
        ),
      ),
    ),
  );
}
Widget _slideFromRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    )),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}
Widget _slideFromBottomTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(curvedAnimation),
    child: FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      child: child,
    ),
  );
}
Widget _scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    ),
    child: FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      ),
      child: child,
    ),
  );
}
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
      // Auth routes - slide from right
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _slideFromRightTransition,
          transitionDuration: _defaultTransitionDuration,
          reverseTransitionDuration: _defaultReverseTransitionDuration,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideFromRightTransition,
          transitionDuration: _defaultTransitionDuration,
          reverseTransitionDuration: _defaultReverseTransitionDuration,
        ),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        name: 'update-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const UpdatePasswordScreen(),
          transitionsBuilder: _slideFromRightTransition,
          transitionDuration: _defaultTransitionDuration,
          reverseTransitionDuration: _defaultReverseTransitionDuration,
        ),
      ),
      // Main map screen - smooth fade+slide (no transition)
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: MainMapScreen(
            userName: (state.extra as Map<String, dynamic>?)?['userName'] ??
                authCubit.state.userName ??
                'User',
          ),
          transitionsBuilder: _smoothPageTransition,
          transitionDuration: _defaultTransitionDuration,
          reverseTransitionDuration: _defaultReverseTransitionDuration,
        ),
        routes: [
          GoRoute(
            path: 'search',
            name: 'search',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NextWhereToScreen(),
              transitionsBuilder: _slideFromBottomTransition,
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 350),
            ),
          ),
          GoRoute(
            path: 'pick-location/:title',
            name: 'pick-location',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: PickLocationScreen(
                title: Uri.decodeComponent(
                    state.pathParameters['title'] ?? 'Pick Location'),
              ),
              transitionsBuilder: _slideFromBottomTransition,
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 350),
            ),
          ),
        ],
      ),
      // Settings - scale+fade
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: _scaleTransition,
          transitionDuration: _defaultTransitionDuration,
          reverseTransitionDuration: _defaultReverseTransitionDuration,
        ),
      ),
      // Add account - slide from bottom
      GoRoute(
        path: AppRoutes.addAccount,
        name: 'add-account',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddAccountScreen(),
          transitionsBuilder: _slideFromBottomTransition,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        ),
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
