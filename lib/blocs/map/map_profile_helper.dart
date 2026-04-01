import 'dart:convert';

import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/profile_service.dart';
import 'map_state.dart';

class MapProfileHelper {
  static Future<void> loadProfile({
    required void Function(MapState) emit,
    required MapState currentState,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = Supabase.instance.client.auth.currentUser?.id;

    double? homeLat;
    double? homeLon;
    double? workLat;
    double? workLon;

    if (uid != null) {
      homeLat = prefs.getDouble('home_lat_$uid');
      homeLon = prefs.getDouble('home_lon_$uid');
      workLat = prefs.getDouble('work_lat_$uid');
      workLon = prefs.getDouble('work_lon_$uid');
    }

    if (homeLat == null || homeLon == null) {
      homeLat = prefs.getDouble('home_lat');
      homeLon = prefs.getDouble('home_lon');
    }
    if (workLat == null || workLon == null) {
      workLat = prefs.getDouble('work_lat');
      workLon = prefs.getDouble('work_lon');
    }

    final customPinsJson =
        prefs.getStringList('custom_pins${uid != null ? '_$uid' : ''}');

    ll.LatLng? home;
    ll.LatLng? work;
    List<Map<String, dynamic>> pins = [];

    if (homeLat != null && homeLon != null) {
      home = ll.LatLng(homeLat, homeLon);
    }
    if (workLat != null && workLon != null) {
      work = ll.LatLng(workLat, workLon);
    }
    if (customPinsJson != null && customPinsJson.isNotEmpty) {
      pins = customPinsJson
          .map((s) {
            try {
              return Map<String, dynamic>.from(
                  json.decode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    try {
      final profile = await ProfileService.loadProfile();
      if (profile.home != null) {
        home = profile.home;
        await prefs.setDouble('home_lat_$uid', profile.home!.latitude);
        await prefs.setDouble('home_lon_$uid', profile.home!.longitude);
      }
      if (profile.work != null) {
        work = profile.work;
        await prefs.setDouble('work_lat_$uid', profile.work!.latitude);
        await prefs.setDouble('work_lon_$uid', profile.work!.longitude);
      }
      if (profile.customPins.isNotEmpty) {
        pins = profile.customPins;
        await prefs.setStringList(
          'custom_pins_$uid',
          pins.map((p) => json.encode(p)).toList(),
        );
      }
    } catch (_) {}

    emit(currentState.copyWith(
      homeLocation: home,
      workLocation: work,
      customPins: pins,
    ));
  }

  static Future<String?> saveHomeLocation(ll.LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_lat', location.latitude);
    await prefs.setDouble('home_lon', location.longitude);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setDouble('home_lat_$uid', location.latitude);
      await prefs.setDouble('home_lon_$uid', location.longitude);
    }
    return await ProfileService.saveHomeLocation(location);
  }

  static Future<String?> saveWorkLocation(ll.LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('work_lat', location.latitude);
    await prefs.setDouble('work_lon', location.longitude);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setDouble('work_lat_$uid', location.latitude);
      await prefs.setDouble('work_lon_$uid', location.longitude);
    }
    return await ProfileService.saveWorkLocation(location);
  }

  static Future<String?> clearHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('home_lat');
    await prefs.remove('home_lon');
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.remove('home_lat_$uid');
      await prefs.remove('home_lon_$uid');
    }
    return await ProfileService.clearHomeLocation();
  }

  static Future<String?> clearWorkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('work_lat');
    await prefs.remove('work_lon');
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.remove('work_lat_$uid');
      await prefs.remove('work_lon_$uid');
    }
    return await ProfileService.clearWorkLocation();
  }

  static Future<void> saveCustomPins(List<Map<String, dynamic>> pins) async {
    final prefs = await SharedPreferences.getInstance();
    final pinsJson = pins.map((p) => json.encode(p)).toList();
    await prefs.setStringList('custom_pins', pinsJson);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setStringList('custom_pins_$uid', pinsJson);
    }
    await ProfileService.saveCustomPins(pins);
  }
}
