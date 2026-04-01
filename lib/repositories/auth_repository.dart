import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/api_response.dart';
/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _client;
  /// Check whether Supabase has been initialized.
  static bool get isInitialized {
    try {
      // Accessing [Supabase.instance] throws if [initialize] was never called.
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  /// Validate password complexity
  String? validatePassword(String password) {
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
  /// Register a new user
  Future<ApiResponse<String>> register({
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
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      if (response.user != null) {
        return ApiResponse.success('Registration successful');
      }
      return ApiResponse.error('Registration failed. Try again.');
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Login user with email and password
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final name =
            response.user!.userMetadata?['full_name'] as String? ?? 'User';
        return ApiResponse.success({'success': true, 'name': name});
      }
      return ApiResponse.error('Login failed.');
    } on AuthException catch (e) {
      String userFriendlyError = e.message;
      if (e.message.contains('Invalid login credentials') ||
          e.code == 'invalid_credentials') {
        try {
          final profileCheck = await _client
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
      return ApiResponse.error(userFriendlyError);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Send password reset email
  Future<ApiResponse<String>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return ApiResponse.success('Password reset email sent');
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Sign out the current user
  Future<ApiResponse<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Update user's name
  Future<ApiResponse<String>> updateName(String newName) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );
      return ApiResponse.success(newName);
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Update user's email
  Future<ApiResponse<String>> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return ApiResponse.success(newEmail);
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Change user's password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return ApiResponse.error('No user is signed in.');
      }
      // Verify current password
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      // Update to new password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return ApiResponse.success(null);
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Update user's date of birth
  Future<ApiResponse<String>> updateDOB(String dob) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'date_of_birth': dob}),
      );
      return ApiResponse.success(dob);
    } on AuthException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  /// Get current user
  User? get currentUser => _client.auth.currentUser;
  /// Get current session
  Session? get currentSession => _client.auth.currentSession;
  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentSession != null;
  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
