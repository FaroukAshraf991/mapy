import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // Register a user into Supabase
  static Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    String? dateOfBirth,
  }) async {
    try {
      final metadata = <String, dynamic>{'full_name': name};
      if (dateOfBirth != null) metadata['date_of_birth'] = dateOfBirth;

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      // Return null on success (no error string)
      if (response.user != null) return null;
      return "Registration failed. Try again.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Attempt login, returning a Map with { 'name': 'User Name', 'error': null }
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
      return {
        'success': false,
        'error': 'Login failed without specific exception.',
      };
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request password reset email
  static Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null; // Return null on success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
