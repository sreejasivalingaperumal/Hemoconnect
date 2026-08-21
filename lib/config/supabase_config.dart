import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// HemoConnect Supabase Configuration & Initialization Manager.
class SupabaseConfig {
  /// Supabase Project URL
  static const String supabaseUrl =
      'https://mhqpbktjhzvltbtnisxr.supabase.co';

  /// Supabase Publishable Key
  static const String supabaseAnonKey =
      'sb_publishable_GhIe0p1wDy03KuNDY-H0vg_V31p9LjF';

  /// Storage bucket for medical reports
  static const String storageBucketMedicalReports =
      'medical-reports';

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );

      if (kDebugMode) {
        print('✅ Supabase initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase initialization error: $e');
      }
    }
  }

  /// Get Supabase client
  static SupabaseClient get client =>
      Supabase.instance.client;
}