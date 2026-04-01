import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a locally stored account entry.
class StoredAccount {
  final String name;
  final String email;
  final String refreshToken;

  const StoredAccount({
    required this.name,
    required this.email,
    required this.refreshToken,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'refreshToken': refreshToken,
      };

  factory StoredAccount.fromJson(Map<String, dynamic> json) => StoredAccount(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );

  StoredAccount copyWith({String? name, String? email, String? refreshToken}) =>
      StoredAccount(
        name: name ?? this.name,
        email: email ?? this.email,
        refreshToken: refreshToken ?? this.refreshToken,
      );
}

/// Manages the list of accounts stored on-device across sessions.
class AccountStorageService {
  static const _key = 'mapy_stored_accounts';
  static final _client = Supabase.instance.client;

  // ── Read ──────────────────────────────────────────────────────────────────

  static Future<List<StoredAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return StoredAccount.fromJson(
                json.decode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<StoredAccount>()
        .toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Saves (or updates) the current signed-in account to the local list.
  static Future<void> saveCurrentAccount() async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    if (user == null || session == null) return;

    final account = StoredAccount(
      name: user.userMetadata?['full_name'] as String? ?? '',
      email: user.email ?? '',
      refreshToken: session.refreshToken ?? '',
    );

    await _upsertAccount(account);
  }

  /// Updates the stored refresh token for a given email (call after any
  /// token refresh so switching back works even with an expired token).
  static Future<void> updateRefreshToken(String email, String refreshToken) async {
    final accounts = await getAccounts();
    final updated = accounts.map((a) {
      if (a.email == email) return a.copyWith(refreshToken: refreshToken);
      return a;
    }).toList();
    await _persist(updated);
  }

  static Future<void> removeAccount(String email) async {
    final accounts = await getAccounts();
    await _persist(accounts.where((a) => a.email != email).toList());
  }

  // ── Switch ────────────────────────────────────────────────────────────────

  /// Switches to [target] account by restoring its Supabase session.
  /// Before switching, the current session's fresh refresh token is persisted.
  static Future<bool> switchTo(StoredAccount target) async {
    // 1. Update stored token for the current account before we leave.
    await saveCurrentAccount();

    // 2. Use setSession — supabase_flutter 2.x supports restoring via tokens.
    try {
      await _client.auth.setSession(target.refreshToken);
      // After sign-in success, persist the new (refreshed) tokens right away.
      await saveCurrentAccount();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<void> _upsertAccount(StoredAccount account) async {
    final accounts = await getAccounts();
    final existing = accounts.indexWhere((a) => a.email == account.email);
    if (existing >= 0) {
      accounts[existing] = account;
    } else {
      accounts.add(account);
    }
    await _persist(accounts);
  }

  static Future<void> _persist(List<StoredAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      accounts.map((a) => json.encode(a.toJson())).toList(),
    );
  }
}
