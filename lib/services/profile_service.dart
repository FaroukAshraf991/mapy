import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for managing user profile data in Supabase.
class ProfileService {
  static final _client = Supabase.instance.client;

  static String? get _uid => _client.auth.currentUser?.id;

  static Future<
      ({
        LatLng? home,
        LatLng? work,
        String? avatarUrl,
        List<Map<String, dynamic>> customPins
      })> loadProfile() async {
    final user = _client.auth.currentUser;
    final uid = user?.id;
    if (uid == null) {
      return (
        home: null,
        work: null,
        avatarUrl: null,
        customPins: <Map<String, dynamic>>[]
      );
    }

    try {
      final data = await _client
          .from('profiles')
          .select(
              'home_lat, home_lon, work_lat, work_lon, avatar_url, custom_pins')
          .eq('id', uid)
          .maybeSingle();

      String? avatarUrl = data?['avatar_url'] as String?;
      avatarUrl ??= user?.userMetadata?['avatar_url'] as String?;

      if (data == null) {
        return (
          home: null,
          work: null,
          avatarUrl: avatarUrl,
          customPins: <Map<String, dynamic>>[]
        );
      }

      return (
        home: _parseLatLng(data['home_lat'], data['home_lon']),
        work: _parseLatLng(data['work_lat'], data['work_lon']),
        avatarUrl: avatarUrl,
        customPins: List<Map<String, dynamic>>.from(data['custom_pins'] ?? []),
      );
    } catch (_) {
      return (
        home: null,
        work: null,
        avatarUrl: user?.userMetadata?['avatar_url'] as String?,
        customPins: <Map<String, dynamic>>[]
      );
    }
  }

  static Future<String?> saveHomeLocation(LatLng loc) async {
    return await _upsert({'home_lat': loc.latitude, 'home_lon': loc.longitude});
  }

  static Future<String?> saveWorkLocation(LatLng loc) async {
    return await _upsert({'work_lat': loc.latitude, 'work_lon': loc.longitude});
  }

  static Future<String?> clearHomeLocation() async {
    return await _upsert({'home_lat': null, 'home_lon': null});
  }

  static Future<String?> clearWorkLocation() async {
    return await _upsert({'work_lat': null, 'work_lon': null});
  }

  static Future<String?> saveCustomPins(List<Map<String, dynamic>> pins) async {
    return await _upsert({'custom_pins': pins});
  }

  static Future<String?> uploadAvatar(File image) async {
    final uid = _uid;
    if (uid == null) return 'Error: No user signed in.';

    try {
      final path = 'avatar-$uid.jpg';
      final bucket = _client.storage.from('avatars');

      try {
        await bucket.remove([path]);
      } catch (_) {}

      await bucket.upload(
        path,
        image,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final url = bucket.getPublicUrl(path);
      final avatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      final dbError = await _upsert({'avatar_url': avatarUrl});
      if (dbError != null) {
        return 'Error saving to profiles: $dbError';
      }

      return avatarUrl;
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<String?> deleteAvatar() async {
    final uid = _uid;
    if (uid == null) return 'Error: No user signed in.';

    try {
      final path = 'avatar-$uid.jpg';
      try {
        await _client.storage.from('avatars').remove([path]);
      } catch (_) {}

      try {
        final files = await _client.storage.from('avatars').list();
        final oldFiles = files
            .where((f) =>
                f.name.startsWith('avatar-$uid-') && f.name.endsWith('.jpg'))
            .map((f) => f.name)
            .toList();
        if (oldFiles.isNotEmpty) {
          await _client.storage.from('avatars').remove(oldFiles);
        }
      } catch (_) {}

      final dbError = await _upsert({'avatar_url': null});
      if (dbError != null) return 'Error clearing profile table: $dbError';

      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': null}),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

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
      return 'Supabase Error: ${e.message} (Code: ${e.code})';
    } catch (e) {
      return 'Unexpected Error: $e';
    }
  }

  static LatLng? _parseLatLng(dynamic lat, dynamic lon) {
    if (lat == null || lon == null) return null;
    return LatLng((lat as num).toDouble(), (lon as num).toDouble());
  }
}
