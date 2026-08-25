import 'package:flutter/material.dart';

/// HemoConnect Premium Palette & Visual Tokens - Modern HealthTech Identity
class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFFC9184A);       // Deep Medical Red
  static const Color primaryDark = Color(0xFFA4133C);   // Rich Burgundy Red
  static const Color primaryLight = Color(0xFFFF4D6D);  // Vibrant Coral
  static const Color secondary = Color(0xFFFF758F);     // Soft Rose Accent
  static const Color accent = Color(0xFFFFB3C1);        // Blush Light Highlight
  static const Color primaryGlow = Color(0x33C9184A);   // Soft Ambient Glow

  // Backgrounds & Surfaces
  static const Color bgLight = Color.fromARGB(255, 249, 244, 245);       // Modern Warm Soft Background
  static const Color surfaceLight = Color(0xFFFFFFFF);  // Pure Elevated White
  static const Color cardLight = Color(0xFFFFFFFF);     // Elevated Card Surface
  
  static const Color bgDark = Color(0xFF090D14);        // Deep Slate Charcoal Dark Mode
  static const Color surfaceDark = Color(0xFF121824);   // Dark Card Surface
  static const Color cardDark = Color(0xFF1A2232);      // Dark Elevated Element

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
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Border & Divider
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF263042);
  static const Color glassBorderLight = Color(0x40FFFFFF);
  static const Color glassBorderDark = Color(0x26FFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF800F2F), Color(0xFFA4133C), Color(0xFFC9184A), Color(0xFFFF4D6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x80FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0xCC1A2232), Color(0x80121824)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Layered BoxShadow System
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primary.withOpacity(0.03),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primary.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primaryButtonGlow = [
    BoxShadow(
      color: primary.withOpacity(0.35),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
