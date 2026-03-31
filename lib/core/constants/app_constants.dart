import 'package:flutter/material.dart';
import 'package:mapy/core/config/secrets.dart';

class AppConstants {
  // Supabase — loaded from --dart-define or secrets_local.txt
  static String get supabaseUrl => Secrets.supabaseUrl;
  static String get supabaseAnonKey => Secrets.supabaseAnonKey;

  // Theme Colors
  static const Color lightBackground = Color(0xFFE0E0E0);
  static const Color darkBackground = Color(0xFF2C2C2C);
  static const Color modalBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF121212);

  // Default Map Position
  static const double defaultLat = 51.5;
  static const double defaultLng = -0.09;
  static const double defaultZoom = 13.0;

  // Map Tile URLs
  static const String osmStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  static const String darkStyleUrl =
      'https://tiles.openfreemap.org/styles/dark';
  static const String satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmTileUserAgent = 'com.example.maps_app';

  // Nominatim
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimUserAgent = 'MapyApp/1.0 (contact@mapy.app)';

  // OSRM Routing
  static const String osrmFootUrl =
      'https://routing.openstreetmap.de/routed-foot';
  static const String osrmBikeUrl =
      'https://routing.openstreetmap.de/routed-bike';
  static const String osrmCarUrl =
      'https://routing.openstreetmap.de/routed-car';
  static const String osrmUserAgent = 'MapyApp/1.0';

  // Navigation Constants
  static const double speedToZoomDivisor = 40.0;
  static const double maxZoomReduction = 3.0;
  static const double speedToTiltDivisor = 5.0;
  static const double maxTiltIncrease = 15.0;
  static const double baseZoom = 18.0;
  static const double baseTilt = 45.0;
  static const double cameraOffsetDistance = 0.0015;
  static const double stepAdvanceDistanceMeters = 35.0;
  static const int notificationThrottleMs = 2500;
  static const int notificationId = 888;

  // Map Throttle
  static const int layerUpdateThrottleMs = 1000;

  // Responsive Design
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  // Search History
  static const int maxSearchHistory = 8;
}
