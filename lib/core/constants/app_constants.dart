import 'package:flutter/material.dart';
import 'package:mapy/core/config/secrets.dart';

class AppConstants {
  // Supabase — loaded from the gitignored secrets.dart file
  static const String supabaseUrl = Secrets.supabaseUrl;
  static const String supabaseAnonKey = Secrets.supabaseAnonKey;

  // Theme Colors (matching splash screen)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkBackground = Color(0xFF0F2027);
}

