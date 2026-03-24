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

  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs the current user out, clearing the persisted session.
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ── Profile Updates ───────────────────────────────────────────────────────

  /// Updates the user's display name in Supabase Auth metadata.
  /// Returns an error message on failure, or null on success.
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

  /// Updates the user's email. Supabase will send a verification email
  /// to the new address. Returns an error message on failure, or null on success.
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

  /// Changes the user's password. Requires the current password for security.
  /// Re-authenticates with the old password first, then updates.
  /// Returns an error message on failure, or null on success.
  static Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return 'No user is signed in.';

      // Re-authenticate with current password
      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update to new password
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

  /// Updates the user's date of birth in Supabase Auth metadata.
  /// Typically used once for users who didn't set it during registration.
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
