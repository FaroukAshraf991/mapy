import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/mixins/fade_slide_animation.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/router/app_routes.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/blocs/auth/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, FadeSlideAnimation {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

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

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both fields.');
      return;
    }

    final result =
        await AuthService.loginUser(email: email, password: password);

    if (!mounted) return;

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      if (!mounted) return;
      // Use GoRouter to navigate - router will handle redirect to map
      context.read<AuthCubit>().login(email: email, password: password);
    } else {
      _showError(result['error'] ??
          'Login failed. Please check your credentials and ensure your email is verified.');
    }
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter your email address first to reset password.');
      return;
    }

    final error = await AuthService.resetPassword(email);
    if (!mounted) return;

    if (error == null) {
      _showSuccess('Password reset link sent! Check your inbox.');
    } else {
      _showError(error);
    }
  }

  void _showError(String msg) {
    FloatingMessage.showError(context, msg);
  }

  void _showSuccess(String msg) {
    FloatingMessage.showSuccess(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
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
                        borderRadius: BorderRadius.circular(context.r(32)),
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
                          Icon(Icons.location_on_rounded,
                              size: context.sp(72), color: Colors.cyanAccent),
                          SizedBox(height: context.h(16)),
                          Text(
                            'Mapy',
                            style: TextStyle(
                                fontSize: context.sp(44),
                                fontWeight: FontWeight.w900,
                                color: Colors.cyanAccent,
                                letterSpacing: 3.0),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: context.h(8)),
                          Text(
                            'Your world, seamlessly mapped.',
                            style: TextStyle(
                                fontSize: context.sp(16),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: context.h(48)),
                          AuthTextField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              isDark: isDark),
                          SizedBox(height: context.h(20)),
                          AuthTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_rounded,
                              isPassword: true,
                              isDark: isDark),
                          SizedBox(height: context.h(12)),
                          Row(
                            children: [
                              Transform.translate(
                                offset: Offset(-context.w(8), 0),
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? false);
                                  },
                                  activeColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(context.r(4))),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(-context.w(14), 0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _rememberMe = !_rememberMe);
                                  },
                                  child: Text('Remember me',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : Colors.black87,
                                          fontSize: context.sp(14))),
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: Text('Forgot Password?',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppConstants.darkBackground
                                              .withValues(alpha: 0.7))),
                            ),
                          ),
                          SizedBox(height: context.h(32)),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  EdgeInsets.symmetric(vertical: context.h(20)),
                              elevation: 12,
                              shadowColor:
                                  Colors.blueAccent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(context.r(20))),
                            ),
                            child: Text('SIGN IN',
                                style: TextStyle(
                                    fontSize: context.sp(18),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0)),
                          ),
                          SizedBox(height: context.h(24)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("New here?",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : Colors.black54)),
                              TextButton(
                                onPressed: () {
                                  context.push(AppRoutes.register);
                                },
                                child: Text('Create Account',
                                    style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: context.sp(16))),
                              ),
                            ],
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
    );
  }
}
