import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/mixins/fade_slide_animation.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/features/auth/widgets/password_requirements.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin, FadeSlideAnimation {
  final _nameController = TextEditingController(),
      _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmController = TextEditingController();
  DateTime? _dateOfBirth;
  String _password = '', _confirmPassword = '';
  bool _confirmPasswordTouched = false;
  bool get _passwordsMatch =>
      _confirmPassword.isNotEmpty &&
      _password.isNotEmpty &&
      _password == _confirmPassword;
  bool get _showConfirmError => _confirmPasswordTouched && !_passwordsMatch;
  @override
  void initState() {
    super.initState();
    initFadeSlideAnimation();
    _passwordController.addListener(
        () => setState(() => _password = _passwordController.text));
    _confirmController.addListener(() => setState(() {
          _confirmPassword = _confirmController.text;
          _confirmPasswordTouched = true;
        }));
  }
  @override
  void dispose() {
    disposeFadeSlideAnimation();
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
        helpText: 'Select your date of birth');
    if (picked != null) setState(() => _dateOfBirth = picked);
  }
  void _register() async {
    final name = _nameController.text.trim(),
        email = _emailController.text.trim(),
        password = _passwordController.text,
        confirm = _confirmController.text;
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
    final passwordError = AuthService.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    final errorMsg = await AuthService.registerUser(
        name: name,
        email: email,
        password: password,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!));
    if (!mounted) return;
    if (errorMsg != null) {
      _showError(errorMsg);
      return;
    }
    _showSuccess(
        'Account created! Please check your email to verify it, then login.');
    Navigator.of(context).pop();
  }
  void _showError(String msg) => FloatingMessage.showError(context, msg);
  void _showSuccess(String msg) => FloatingMessage.showSuccess(context, msg);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
              color: isDark ? Colors.white : AppConstants.darkBackground)),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.maxAuthWidth),
                  child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                  child: FadeTransition(
                      opacity: fadeAnimation,
                      child: SlideTransition(
                          position: slideAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.r(32)),
                            child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.05),
                                          width: 1.5)),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text('Join Mapy',
                                            style: TextStyle(
                                                fontSize: context.sp(36),
                                                fontWeight: FontWeight.w900,
                                                color: Colors.cyanAccent,
                                                letterSpacing: 2.0),
                                            textAlign: TextAlign.center),
                                        SizedBox(height: context.h(8)),
                                        Text('Create your profile',
                                            style: TextStyle(
                                                fontSize: context.sp(16),
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.7)
                                                    : Colors.black54),
                                            textAlign: TextAlign.center),
                                        SizedBox(height: context.h(32)),
                                        AuthTextField(
                                            controller: _nameController,
                                            hint: 'Full Name',
                                            icon: Icons.person_rounded,
                                            isDark: isDark),
                                        SizedBox(height: context.h(20)),
                                        _buildDatePicker(isDark),
                                        SizedBox(height: context.h(20)),
                                        AuthTextField(
                                            controller: _emailController,
                                            hint: 'Email Address',
                                            icon: Icons.email_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            isDark: isDark),
                                        SizedBox(height: context.h(20)),
                                        AuthTextField(
                                            controller: _passwordController,
                                            hint: 'Password',
                                            icon: Icons.lock_rounded,
                                            isPassword: true,
                                            isDark: isDark),
                                        SizedBox(height: context.h(12)),
                                        PasswordRequirements(
                                            password: _password,
                                            isDark: isDark),
                                        SizedBox(height: context.h(20)),
                                        AuthTextField(
                                            controller: _confirmController,
                                            hint: 'Confirm Password',
                                            icon: Icons.lock_outline_rounded,
                                            isPassword: true,
                                            isDark: isDark,
                                            showError: _showConfirmError),
                                        SizedBox(height: context.h(40)),
                                        ElevatedButton(
                                            onPressed: _register,
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: context.h(20)),
                                                elevation: 12,
                                                shadowColor: Colors.blueAccent
                                                    .withValues(alpha: 0.4),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            context.r(20)))),
                                            child: Text('CREATE ACCOUNT',
                                                style: TextStyle(
                                                    fontSize: context.sp(18),
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5))),
                                      ]),
                                )),
                          ))))))),
    );
  }
  Widget _buildDatePicker(bool isDark) => Semantics(
      button: true,
      label: 'Pick Date of Birth',
      child: GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(16)),
        decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(context.r(16)),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                width: 1)),
        child: Row(children: [
          Icon(Icons.cake_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black87),
          SizedBox(width: context.w(12)),
          Text(
              _dateOfBirth != null
                  ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                  : 'Date of Birth',
              style: TextStyle(
                  fontSize: context.sp(16),
                  color: _dateOfBirth != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black54))),
        ]),
      )));
}
