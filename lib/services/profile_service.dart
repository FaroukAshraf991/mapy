import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles reading and writing the user's profile (Home/Work locations +
/// avatar) to the `profiles` table and `avatars` Supabase Storage bucket.
class ProfileService {
  static final _client = Supabase.instance.client;

  static String? get _uid => _client.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  static Future<({LatLng? home, LatLng? work, String? avatarUrl, List<Map<String, dynamic>> customPins})>
      loadProfile() async {
    final user = _client.auth.currentUser;
    final uid = user?.id;
    if (uid == null) return (home: null, work: null, avatarUrl: null, customPins: <Map<String, dynamic>>[]);

    try {
      final data = await _client
          .from('profiles')
          .select('home_lat, home_lon, work_lat, work_lon, avatar_url, custom_pins')
          .eq('id', uid)
          .maybeSingle();

      String? avatarUrl = data?['avatar_url'] as String?;
      
      // Fallback to user metadata if not found in profiles table
      avatarUrl ??= user?.userMetadata?['avatar_url'] as String?;

      if (data == null) {
        return (home: null, work: null, avatarUrl: avatarUrl, customPins: <Map<String, dynamic>>[]);
      }

      return (
        home: _parseLatLng(data['home_lat'], data['home_lon']),
        work: _parseLatLng(data['work_lat'], data['work_lon']),
        avatarUrl: avatarUrl,
        customPins: List<Map<String, dynamic>>.from(data['custom_pins'] ?? []),
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      // Even on error, try to return avatar from metadata
      return (home: null, work: null, avatarUrl: user?.userMetadata?['avatar_url'] as String?, customPins: <Map<String, dynamic>>[]);
    }
  }

  // ── Location Write ────────────────────────────────────────────────────────

  static Future<void> saveHomeLocation(LatLng loc) async {
    await _upsert({'home_lat': loc.latitude, 'home_lon': loc.longitude});
  }

  static Future<void> saveWorkLocation(LatLng loc) async {
    await _upsert({'work_lat': loc.latitude, 'work_lon': loc.longitude});
  }

  static Future<void> clearHomeLocation() async {
    await _upsert({'home_lat': null, 'home_lon': null});
  }

  static Future<void> clearWorkLocation() async {
    await _upsert({'work_lat': null, 'work_lon': null});
  }

  static Future<void> saveCustomPins(List<Map<String, dynamic>> pins) async {
    await _upsert({'custom_pins': pins});
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  /// Uploads [image] to Supabase Storage and returns the public URL,
  /// or null on failure.
  static Future<String?> uploadAvatar(File image) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final bytes = await image.readAsBytes();
      final path = '$uid/avatar.jpg';

      // 1. Upload to Storage
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);

      // Cache busting: append a timestamp so the widget re-fetches the image
      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // 2. Update profiles table
      await _upsert({'avatar_url': bustUrl});
      
      // 3. Update auth metadata as a fallback
      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': bustUrl}),
      );
      
      return bustUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Future<void> _upsert(Map<String, dynamic> fields) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client.from('profiles').upsert({
        'id': uid,
        'updated_at': DateTime.now().toIso8601String(),
        ...fields,
      });
    } catch (e) {
      debugPrint('Error upserting profile: $e');
    }
  }

  static LatLng? _parseLatLng(dynamic lat, dynamic lon) {
    if (lat == null || lon == null) return null;
    return LatLng((lat as num).toDouble(), (lon as num).toDouble());
  }
}
