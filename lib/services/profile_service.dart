import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for managing user profile data in Supabase.
/// This includes Home/Work locations, custom favorite pins, and profile avatars.
/// 
/// It implements a "dual-storage" strategy for avatars to ensure high reliability.
class ProfileService {
  static final _client = Supabase.instance.client;

  /// Returns the current authenticated user's ID.
  static String? get _uid => _client.auth.currentUser?.id;

  // ── READ OPERATIONS ────────────────────────────────────────────────────────

  /// Loads the full profile for the currently authenticated user.
  /// 
  /// Returns a record containing:
  /// - [home]: Saved home coordinates (LatLng?).
  /// - [work]: Saved work coordinates (LatLng?).
  /// - [avatarUrl]: The public URL for the profile picture.
  /// - [customPins]: A list of user-defined favorite places.
  /// 
  /// Note: [avatarUrl] implements a fallback to Auth Metadata if the 
  /// profiles table lookup fails or is empty.
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
      
      // FALLBACK: Load from user metadata if not found in profiles table.
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
      debugPrint('Error loading profile (check if custom_pins column exists): $e');
      // On error, still return the metadata avatar if available.
      return (home: null, work: null, avatarUrl: user?.userMetadata?['avatar_url'] as String?, customPins: <Map<String, dynamic>>[]);
    }
  }

  // ── LOCATION WRITE OPERATIONS ──────────────────────────────────────────────

  /// Persists the user's Home location to the database.
  static Future<String?> saveHomeLocation(LatLng loc) async {
    return await _upsert({'home_lat': loc.latitude, 'home_lon': loc.longitude});
  }

  /// Persists the user's Work location to the database.
  static Future<String?> saveWorkLocation(LatLng loc) async {
    return await _upsert({'work_lat': loc.latitude, 'work_lon': loc.longitude});
  }

  /// Removes the user's Home location from the database.
  static Future<String?> clearHomeLocation() async {
    return await _upsert({'home_lat': null, 'home_lon': null});
  }

  /// Removes the user's Work location from the database.
  static Future<String?> clearWorkLocation() async {
    return await _upsert({'work_lat': null, 'work_lon': null});
  }

  /// Saves the entire list of custom favorite pins (shortcuts) to the database.
  static Future<String?> saveCustomPins(List<Map<String, dynamic>> pins) async {
    return await _upsert({'custom_pins': pins});
  }

  // ── AVATAR OPERATIONS ──────────────────────────────────────────────────────

  /// Uploads a new profile picture to Supabase Storage.
  /// 
  /// Logic:
  /// 1. Uploads binary data to the 'avatars' bucket.
  /// 2. Updates the 'avatar_url' in the `profiles` table.
  /// 3. Updates the `user_metadata` in Supabase Auth (Fallback storage).
  /// 
  /// [image]: The local file to upload.
  /// Returns the public URL of the uploaded image, or null on failure.
  static Future<String?> uploadAvatar(File image) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final bytes = await image.readAsBytes();
      final path = '$uid/avatar.jpg';

      // 1. UPLOAD BINARY TO STORAGE
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);

      // Cache busting: append a timestamp to force high-level widgets to refresh.
      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // 2. UPDATE PROFILES TABLE
      await _upsert({'avatar_url': bustUrl});
      
      // 3. UPDATE AUTH METADATA (Dual-persistence for reliability)
      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': bustUrl}),
      );
      
      return bustUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// Performs an upsert (insert or update) on the user's profile record.
  /// Returns an error message if the operation fails, or null on success.
  static Future<String?> _upsert(Map<String, dynamic> fields) async {
    final uid = _uid;
    if (uid == null) return 'No user signed in.';
    try {
      await _client.from('profiles').upsert({
        'id': uid,
        'updated_at': DateTime.now().toIso8601String(),
        ...fields,
      });
      return null;
    } on PostgrestException catch (e) {
      final msg = 'Supabase Error: ${e.message} (Code: ${e.code})';
      debugPrint(msg);
      return msg;
    } catch (e) {
      final msg = 'Unexpected Error: $e';
      debugPrint(msg);
      return msg;
    }
  }

  /// Safe parser for LatLng data from dynamic JSON/Map fields.
  static LatLng? _parseLatLng(dynamic lat, dynamic lon) {
    if (lat == null || lon == null) return null;
    return LatLng((lat as num).toDouble(), (lon as num).toDouble());
  }
}

