import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase authentication operations.
class AuthService {
  static final _supabase = Supabase.instance.client;

  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  static Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    String? dateOfBirth,
  }) async {
    try {
      final metadata = <String, dynamic>{'full_name': name};
      if (dateOfBirth != null) {
        metadata['date_of_birth'] = dateOfBirth;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      if (response.user != null) return null;
      return 'Registration failed. Try again.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final name =
            response.user!.userMetadata?['full_name'] as String? ?? 'User';
        return {'success': true, 'name': name};
      }
      return {'success': false, 'error': 'Login failed.'};
    } on AuthException catch (e) {
      String userFriendlyError = e.message;

      if (e.message.contains('Invalid login credentials') ||
          e.code == 'invalid_credentials') {
        try {
          final profileCheck = await _supabase
              .from('profiles')
              .select('id')
              .eq('email', email)
              .maybeSingle();

          if (profileCheck != null) {
            userFriendlyError = 'Incorrect password. Please try again.';
          } else {
            userFriendlyError =
                'No account found with this email. Check for typos or register below.';
          }
        } catch (_) {}
      } else if (e.message.contains('Email not confirmed')) {
        userFriendlyError =
            'Please verify your email address before logging in.';
      }

      return {'success': false, 'error': userFriendlyError};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  static Future<String?> updateName(String newName) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return 'No user is signed in.';

      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> updateDOB(String dob) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'date_of_birth': dob}),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
