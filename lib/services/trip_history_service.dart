import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart' as ll;

class TripHistoryService {
  static const String _tripHistoryKey = 'trip_history';
  static const int _maxTrips = 50;

  static Future<List<TripRecord>> getTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripHistoryKey) ?? [];
    return tripsJson.map((json) {
      return TripRecord.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static Future<void> saveTrip(TripRecord trip) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripHistoryKey) ?? [];

    tripsJson.insert(0, jsonEncode(trip.toJson()));

    while (tripsJson.length > _maxTrips) {
      tripsJson.removeLast();
    }

    await prefs.setStringList(_tripHistoryKey, tripsJson);
  }

  static Future<void> clearTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tripHistoryKey);
  }

  static Future<void> deleteTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripHistoryKey) ?? [];
    tripsJson.removeWhere((json) {
      final trip =
          TripRecord.fromJson(jsonDecode(json) as Map<String, dynamic>);
      return trip.id == tripId;
    });
    await prefs.setStringList(_tripHistoryKey, tripsJson);
  }

  static String generateGpx(List<ll.LatLng> points, String tripName) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Mapy App">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>$tripName</name>');
    buffer.writeln('    <trkseg>');
    for (final point in points) {
      buffer.writeln(
          '      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      buffer.writeln('      </trkpt>');
    }
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }
}

class TripRecord {
  final String id;
  final String destinationName;
  final ll.LatLng destination;
  final double distanceMeters;
  final int durationSeconds;
  final DateTime startTime;
  final DateTime? endTime;
  final List<Map<String, double>> waypoints;

  TripRecord({
    required this.id,
    required this.destinationName,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startTime,
    this.endTime,
    this.waypoints = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'destinationName': destinationName,
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude
        },
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'waypoints': waypoints,
      };

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    final dest = json['destination'] as Map<String, dynamic>;
    return TripRecord(
      id: json['id'] as String,
      destinationName: json['destinationName'] as String,
      destination: ll.LatLng(dest['lat'] as double, dest['lng'] as double),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((e) => Map<String, double>.from(e as Map))
              .toList() ??
          [],
    );
  }

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final minutes = durationSeconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
