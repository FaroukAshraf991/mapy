import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/api_response.dart';

/// Repository for profile operations
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Load user profile data
  Future<
      ApiResponse<
          ({
            LatLng? home,
            LatLng? work,
            String? avatarUrl,
            List<Map<String, dynamic>> customPins,
          })>> loadProfile() async {
    final user = _client.auth.currentUser;
    final uid = user?.id;
    if (uid == null) {
      return ApiResponse.success((
        home: null,
        work: null,
        avatarUrl: null,
        customPins: <Map<String, dynamic>>[],
      ));
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

      return ApiResponse.success((
        home: _parseLatLng(data?['home_lat'], data?['home_lon']),
        work: _parseLatLng(data?['work_lat'], data?['work_lon']),
        avatarUrl: avatarUrl,
        customPins: List<Map<String, dynamic>>.from(data?['custom_pins'] ?? []),
      ));
    } catch (e) {
      return ApiResponse.success((
        home: null,
        work: null,
        avatarUrl: user?.userMetadata?['avatar_url'] as String?,
        customPins: <Map<String, dynamic>>[],
      ));
    }
  }

  /// Save home location
  Future<ApiResponse<void>> saveHomeLocation(LatLng loc) async {
    return await _upsert({'home_lat': loc.latitude, 'home_lon': loc.longitude});
  }

  /// Save work location
  Future<ApiResponse<void>> saveWorkLocation(LatLng loc) async {
    return await _upsert({'work_lat': loc.latitude, 'work_lon': loc.longitude});
  }

  /// Clear home location
  Future<ApiResponse<void>> clearHomeLocation() async {
    return await _upsert({'home_lat': null, 'home_lon': null});
  }

  /// Clear work location
  Future<ApiResponse<void>> clearWorkLocation() async {
    return await _upsert({'work_lat': null, 'work_lon': null});
  }

  /// Save custom pins
  Future<ApiResponse<void>> saveCustomPins(
      List<Map<String, dynamic>> pins) async {
    return await _upsert({'custom_pins': pins});
  }

  /// Upload avatar image
  Future<ApiResponse<String>> uploadAvatar(File image) async {
    final uid = _uid;
    if (uid == null) {
      return ApiResponse.error('No user signed in.');
    }

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

      final result = await _upsert({'avatar_url': avatarUrl});
      if (!result.success) {
        return ApiResponse.error(result.error ?? 'Error saving avatar URL');
      }

      return ApiResponse.success(avatarUrl);
    } catch (e) {
      return ApiResponse.error('Upload failed: $e');
    }
  }

  /// Delete avatar
  Future<ApiResponse<void>> deleteAvatar() async {
    final uid = _uid;
    if (uid == null) {
      return ApiResponse.error('No user signed in.');
    }

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

      final result = await _upsert({'avatar_url': null});
      if (!result.success) {
        return ApiResponse.error(result.error ?? 'Error clearing avatar');
      }

      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': null}),
      );

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Upsert profile data
  Future<ApiResponse<void>> _upsert(Map<String, dynamic> fields) async {
    final uid = _uid;
    if (uid == null) {
      return ApiResponse.error('No user signed in.');
    }

    try {
      await _client.from('profiles').upsert({
        'id': uid,
        'updated_at': DateTime.now().toIso8601String(),
        ...fields,
      });
      return ApiResponse.success(null);
    } on PostgrestException catch (e) {
      return ApiResponse.error('Database error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Parse lat/lng from dynamic values
  LatLng? _parseLatLng(dynamic lat, dynamic lon) {
    if (lat == null || lon == null) return null;
    return LatLng((lat as num).toDouble(), (lon as num).toDouble());
  }
}
