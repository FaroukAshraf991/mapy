import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapy/models/place_result.dart';

/// Persists up to [_maxHistory] recently searched [PlaceResult]s locally
/// using [SharedPreferences].
class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 8;

  /// Returns the saved search history, newest first.
  static Future<List<PlaceResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        return PlaceResult.fromJson(
            json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<PlaceResult>().toList();
  }

  /// Prepends [place] to the history, deduplicates, and trims to [_maxHistory].
  static Future<void> addToHistory(PlaceResult place) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    // Remove duplicates by display name
    final updated = [
      json.encode(place.toJson()),
      ...existing.where((s) {
        try {
          final decoded =
              json.decode(s) as Map<String, dynamic>;
          return decoded['display_name'] != place.displayName;
        } catch (_) {
          return true;
        }
      }),
    ];

    await prefs.setStringList(
        _key, updated.take(_maxHistory).toList());
  }

  /// Clears all saved history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
