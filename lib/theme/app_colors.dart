import 'package:flutter/material.dart';

/// HemoConnect Curated Palette - Modern HealthTech Visual Identity
class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFFC9184A);       // Deep Medical Red
  static const Color primaryDark = Color(0xFFA4133C);   // Rich Burgundy Red
  static const Color primaryLight = Color(0xFFFF4D6D);  // Vibrant Coral
  static const Color secondary = Color(0xFFFF758F);     // Soft Rose Accent
  static const Color accent = Color(0xFFFFB3C1);        // Blush Light Highlight

  // Backgrounds & Surface
  static const Color bgLight = Color(0xFFF8F9FA);       // Very Warm Light Grey / Off-White
  static const Color surfaceLight = Color(0xFFFFFFFF);  // Pure White
  static const Color cardLight = Color(0xFFFFFFFF);     // Elevated Card Surface
  
  static const Color bgDark = Color(0xFF0D1117);        // Deep Charcoal / Navy Dark Mode
  static const Color surfaceDark = Color(0xFF161B22);   // Dark Card Surface
  static const Color cardDark = Color(0xFF21262D);      // Dark Elevated Element

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);       // Emerald Green (Approved / Completed)
  static const Color successBg = Color(0xFFECFDF5);     // Soft Emerald Light Bg
  static const Color warning = Color(0xFFF59E0B);       // Amber Orange (Pending / Processing)
  static const Color warningBg = Color(0xFFFFFBEB);     // Soft Amber Light Bg
  static const Color danger = Color(0xFFEF4444);        // Medical Warning Red (Rejected / Emergency)
  static const Color dangerBg = Color(0xFFFEF2F2);      // Soft Red Light Bg
  static const Color info = Color(0xFF3B82F6);          // Sapphire Blue
  static const Color infoBg = Color(0xFFEFF6FF);        // Soft Sapphire Light Bg

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Border & Divider
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF30363D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [danger, Color(0xFFDC2626), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
