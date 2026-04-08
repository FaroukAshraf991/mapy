import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/core/constants/app_constants.dart';

/// Persists recently searched places, syncing with Supabase and local cache.
class SearchHistoryService {
  static final _client = Supabase.instance.client;

  static String _localKey(String userId) => 'search_history_$userId';

  static Future<List<PlaceResult>> getHistory(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('search_history')
          .eq('id', userId)
          .maybeSingle();

      if (data != null && data['search_history'] != null) {
        final List<dynamic> items = data['search_history'];
        final history = items
            .map((item) {
              try {
                return PlaceResult.fromJson(
                    Map<String, dynamic>.from(item as Map));
              } catch (_) {
                return null;
              }
            })
            .whereType<PlaceResult>()
            .toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _localKey(userId),
          history.map((p) => json.encode(p.toJson())).toList(),
        );
        return history;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey(userId)) ?? [];
    return raw
        .map((s) {
          try {
            return PlaceResult.fromJson(json.decode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PlaceResult>()
        .toList();
  }

  static Future<void> addToHistory(String userId, PlaceResult place) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_localKey(userId)) ?? [];

    final updated = [
      json.encode(place.toJson()),
      ...existing.where((s) {
        try {
          final decoded = json.decode(s) as Map<String, dynamic>;
          return decoded['display_name'] != place.displayName;
        } catch (_) {
          return true;
        }
      }),
    ];

    final trimmed = updated.take(AppConstants.maxSearchHistory).toList();
    await prefs.setStringList(_localKey(userId), trimmed);

    try {
      final historyJson = trimmed.map((s) => json.decode(s)).toList();
      await _client.from('profiles').upsert({
        'id': userId,
        'search_history': historyJson,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> replaceHistory(
      String userId, List<PlaceResult> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList(_localKey(userId), encoded);

    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'search_history': items.map((p) => p.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> clearHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey(userId));

    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'search_history': [],
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
