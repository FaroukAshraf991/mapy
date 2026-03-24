import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  DateTime? _dateOfBirth;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (_dateOfBirth == null) {
      _showError('Please select your date of birth.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    final dobStr = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    final errorMsg = await AuthService.registerUser(name: name, email: email, password: password, dateOfBirth: dobStr);

    if (!mounted) return;
    
    if (errorMsg != null) {
      _showError(errorMsg);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created! Please check your email to verify it, then login.'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppConstants.darkBackground),
      ),
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
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Join Mapy', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 2.0), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('Create your profile', style: TextStyle(fontSize: 16, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54), textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          AuthTextField(controller: _nameController, hint: 'Full Name', icon: Icons.person_rounded, isDark: isDark),
                          const SizedBox(height: 20),
                          // Date of Birth picker
                          GestureDetector(
                            onTap: _pickDateOfBirth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.cake_rounded, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87),
                                  const SizedBox(width: 12),
                                  Text(
                                    _dateOfBirth != null
                                        ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                                        : 'Date of Birth',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _dateOfBirth != null
                                          ? (isDark ? Colors.white : Colors.black87)
                                          : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AuthTextField(controller: _emailController, hint: 'Email Address', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, isDark: isDark),
                          const SizedBox(height: 20),
                          AuthTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_rounded, isPassword: true, isDark: isDark),
                          const SizedBox(height: 20),
                          AuthTextField(controller: _confirmController, hint: 'Confirm Password', icon: Icons.lock_outline_rounded, isPassword: true, isDark: isDark),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              elevation: 12,
                              shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
