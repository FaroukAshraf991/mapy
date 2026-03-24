import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';
import 'package:mapy/features/auth/screens/register_screen.dart';
import 'package:mapy/features/auth/screens/update_password_screen.dart';
import 'package:mapy/features/map/screens/main_map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    // Listen for Password Recovery deep-link events from Supabase
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _animController.dispose();
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

    final result = await AuthService.loginUser(email: email, password: password);

    if (!mounted) return;

    if (result['success'] == true) {
      final userName = result['name'];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainMapScreen(userName: userName)),
      );
    } else {
      _showError(result['error'] ?? 'Login failed. Please check your credentials and ensure your email is verified.');
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent! Check your inbox.'), backgroundColor: Colors.green));
    } else {
      _showError(error);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : AppConstants.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.location_on_rounded, size: 72, color: Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Text(
                            'Mapy',
                            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 3.0),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your world, seamlessly mapped.',
                            style: TextStyle(fontSize: 16, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          AuthTextField(controller: _emailController, hint: 'Email Address', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, isDark: isDark),
                          const SizedBox(height: 20),
                          AuthTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_rounded, isPassword: true, isDark: isDark),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: Text('Forgot Password?', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.8) : AppConstants.darkBackground.withValues(alpha: 0.7))),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              elevation: 12,
                              shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('SIGN IN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("New here?", style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54)),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                                },
                                child: Text('Create Account', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 16)),
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
