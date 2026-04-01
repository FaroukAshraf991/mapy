import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/mixins/fade_slide_animation.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/router/app_routes.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/services/account_storage_service.dart';

/// Sign-in screen for adding a second (or different) account.
/// Does NOT log out the current account before the user taps "Sign In".
/// When sign-in succeeds, the new session takes over and we navigate to /map.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin, FadeSlideAnimation {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initFadeSlideAnimation();
  }

  @override
  void dispose() {
    disposeFadeSlideAnimation();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both fields.');
      return;
    }

    setState(() => _isLoading = true);

    // AuthService.loginUser signs in without touching AuthCubit state first
    // — this means the current account is NOT logged out until Supabase
    // replaces the session on successful sign-in.
    final result = await AuthService.loginUser(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Persist the new account so it shows up in the account switcher.
      await AccountStorageService.saveCurrentAccount();
      if (!mounted) return;
      context.go(AppRoutes.map);
    } else {
      _showError(result['error'] ??
          'Sign in failed. Please check your credentials.');
    }
  }

  void _showError(String msg) => FloatingMessage.showError(context, msg);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with back button ───────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: context.sp(20),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),

            // ── Main card ─────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.r(32)),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: EdgeInsets.all(context.w(32)),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius:
                                  BorderRadius.circular(context.r(32)),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Icon + branding
                                Icon(Icons.person_add_alt_1_rounded,
                                    size: context.sp(64),
                                    color: Colors.cyanAccent),
                                SizedBox(height: context.h(16)),
                                Text(
                                  'Add Account',
                                  style: TextStyle(
                                    fontSize: context.sp(36),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.cyanAccent,
                                    letterSpacing: 2.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: context.h(8)),
                                Text(
                                  'Sign in to switch to another account.',
                                  style: TextStyle(
                                    fontSize: context.sp(14),
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: context.h(40)),

                                // Email field
                                AuthTextField(
                                  controller: _emailController,
                                  hint: 'Email Address',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  isDark: isDark,
                                ),
                                SizedBox(height: context.h(20)),

                                // Password field
                                AuthTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                  isDark: isDark,
                                ),

                                SizedBox(height: context.h(36)),

                                // Sign In button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.cyanAccent
                                        .withValues(alpha: 0.4),
                                    padding: EdgeInsets.symmetric(
                                        vertical: context.h(20)),
                                    elevation: 12,
                                    shadowColor:
                                        Colors.cyanAccent.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(context.r(20)),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: context.h(22),
                                          width: context.h(22),
                                          child: const CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontSize: context.sp(18),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                ),

                                SizedBox(height: context.h(16)),

                                // Cancel
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                      fontSize: context.sp(15),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
