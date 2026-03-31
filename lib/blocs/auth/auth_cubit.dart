import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/auth_repository.dart';

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
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check existing session
    final session = _authRepository.currentSession;
    if (session != null) {
      final user = session.user;
      final name = user.userMetadata?['full_name'] as String? ?? 'User';
      emit(AuthState(status: AuthStatus.authenticated, userName: name));
    }

    // Listen to auth state changes
    _authRepository.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          final user = data.session?.user;
          final name = user?.userMetadata?['full_name'] as String? ?? 'User';
          emit(AuthState(status: AuthStatus.authenticated, userName: name));
          break;
        case AuthChangeEvent.signedOut:
          emit(const AuthState(status: AuthStatus.unauthenticated));
          break;
        case AuthChangeEvent.passwordRecovery:
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
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (result.success && result.data != null) {
      final name = result.data!['name'] as String? ?? 'User';
      emit(AuthState(status: AuthStatus.authenticated, userName: name));
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
    await _authRepository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Reset password
  Future<String?> resetPassword(String email) async {
    final result = await _authRepository.resetPassword(email);
    return result.error;
  }

  /// Update name
  Future<void> updateName(String newName) async {
    final result = await _authRepository.updateName(newName);
    if (result.success) {
      emit(state.copyWith(userName: newName));
    }
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
