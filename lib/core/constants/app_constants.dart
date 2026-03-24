import 'package:flutter/material.dart';
import 'package:mapy/core/config/secrets.dart';

class AppConstants {
  // Supabase — loaded from the gitignored secrets.dart file
  static const String supabaseUrl = Secrets.supabaseUrl;
  static const String supabaseAnonKey = Secrets.supabaseAnonKey;

  // Theme Colors (matching splash screen)
  static const Color lightBackground = Color(0xFFE0E0E0); // Grey 300
  static const Color darkBackground = Color(0xFF2C2C2C); // Dark Grey
}

