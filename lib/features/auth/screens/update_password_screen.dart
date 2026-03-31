import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/widgets/auth_text_field.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/features/auth/widgets/password_requirements.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String _password = '';
  String _confirmPassword = '';
  bool _confirmPasswordTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmController.addListener(_onConfirmPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Supabase.instance.client.auth.currentSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Verification failed. Your session may have expired.'),
              backgroundColor: Colors.redAccent),
        );
        Navigator.of(context).pop();
      }
    });
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _passwordController.text;
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _confirmPassword = _confirmController.text;
      _confirmPasswordTouched = true;
    });
  }

  bool get _passwordsMatch =>
      _confirmPassword.isNotEmpty &&
      _password.isNotEmpty &&
      _password == _confirmPassword;
  bool get _showConfirmError => _confirmPasswordTouched && !_passwordsMatch;

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmController.removeListener(_onConfirmPasswordChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    final passwordError = AuthService.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: password));
      if (!mounted) return;
      _showSuccess('Password updated successfully! Welcome back.');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : AppConstants.darkBackground),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create New Password',
                  style: TextStyle(
                      fontSize: context.sp(28),
                      fontWeight: FontWeight.bold,
                      color: textColor),
                  textAlign: TextAlign.center),
              SizedBox(height: context.h(32)),
              AuthTextField(
                  controller: _passwordController,
                  hint: 'New Password',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  isDark: isDark),
              SizedBox(height: context.h(12)),
              PasswordRequirements(password: _password, isDark: isDark),
              SizedBox(height: context.h(20)),
              AuthTextField(
                  controller: _confirmController,
                  hint: 'Confirm New Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  isDark: isDark,
                  showError: _showConfirmError),
              SizedBox(height: context.h(40)),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: context.h(20)),
                        elevation: 12,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(20))),
                      ),
                      child: Text('UPDATE PASSWORD',
                          style: TextStyle(
                              fontSize: context.sp(18),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
