import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase authentication operations:
/// register, login, and password reset.
class AuthService {
  static final _supabase = Supabase.instance.client;

  // ── Register ──────────────────────────────────────────────────────────────

  /// Creates a new user account. Returns an error message on failure,
  /// or null on success.
  static Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user != null) return null;
      return 'Registration failed. Try again.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Signs in an existing user.
  /// Returns `{'success': true, 'name': '...'}` or `{'success': false, 'error': '...'}`.
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
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password-reset email. Returns an error string on failure,
  /// or null on success.
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
}
