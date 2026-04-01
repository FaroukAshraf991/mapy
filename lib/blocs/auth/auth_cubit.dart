import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../repositories/auth_repository.dart';
import '../../services/account_storage_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? userName;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userName,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userName,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userName: userName ?? this.userName,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository? _authRepository;
  StreamSubscription<supa.AuthState>? _authSubscription;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ??
            (AuthRepository.isInitialized ? AuthRepository() : null),
        super(const AuthState()) {
    _init();
  }

  void _init() {
    // If Supabase was not initialized, stay unauthenticated — the user will
    // see the login screen and can retry from there.
    if (_authRepository == null) return;

    // Check existing session
    final session = _authRepository.currentSession;
    if (session != null) {
      final user = session.user;
      final name = user.userMetadata?['full_name'] as String? ?? 'User';
      emit(AuthState(status: AuthStatus.authenticated, userName: name));
    }

    // Listen to auth state changes — store subscription so close() can cancel it
    _authSubscription = _authRepository.onAuthStateChange.listen((data) {
      if (isClosed) return; // extra safety guard
      switch (data.event) {
        case supa.AuthChangeEvent.signedIn:
          final user = data.session?.user;
          final name = user?.userMetadata?['full_name'] as String? ?? 'User';
          emit(AuthState(status: AuthStatus.authenticated, userName: name));
          break;
        case supa.AuthChangeEvent.signedOut:
          emit(const AuthState(status: AuthStatus.unauthenticated));
          break;
        case supa.AuthChangeEvent.passwordRecovery:
          // Handle password recovery - router will handle redirect
          break;
        default:
          break;
      }
    });
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (_authRepository == null) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Service unavailable. Please try again later.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (result.success && result.data != null) {
      final name = result.data!['name'] as String? ?? 'User';
      emit(AuthState(status: AuthStatus.authenticated, userName: name));
      // Persist this account so the switcher can show & restore it later.
      await AccountStorageService.saveCurrentAccount();
    } else {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        error: result.error,
      ));
    }
  }

  /// Register new user
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? dateOfBirth,
  }) async {
    if (_authRepository == null) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Service unavailable. Please try again later.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _authRepository.register(
      name: name,
      email: email,
      password: password,
      dateOfBirth: dateOfBirth,
    );

    if (result.success) {
      emit(AuthState(status: AuthStatus.authenticated, userName: name));
    } else {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        error: result.error,
      ));
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository?.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Reset password
  Future<String?> resetPassword(String email) async {
    final result = await _authRepository?.resetPassword(email);
    return result?.error;
  }

  /// Update name
  Future<void> updateName(String newName) async {
    final result = await _authRepository?.updateName(newName);
    if (result?.success == true) {
      emit(state.copyWith(userName: newName));
    }
  }

  /// Update userName in state (e.g., after account switch without making API call)
  void setUserName(String newName) {
    emit(state.copyWith(userName: newName));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(error: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
