import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Centralized Premium Design System
/// ─────────────────────────────────────────────────────────
///
/// Single source of truth for every color in the app.
/// Both light and dark modes derive from ONE premium palette.
/// No legacy aliases, no duplicates.
class AppColors {
  AppColors._(); // prevent instantiation

  // ═══════════════════════ BRAND — PREMIUM ORANGE ═══════════════════════

  /// Primary accent — CTAs, icons, selected states
  static const Color orange = Color(0xFFFF7A3D);

  /// Pressed/gradient-end variant
  static const Color orangeDark = Color(0xFFE65F22);

  /// Gradient end — lighter orange
  static const Color orangeLight = Color(0xFFFF9A6C);

  /// Tinted surface — chip backgrounds, highlights
  static const Color orangeSoft = Color(0xFFFFE7DB);

  /// Shadow/glow for selected elements (25% orange)
  static const Color orangeGlow = Color(0x40FF7A3D);

  // ═══════════════════════ SURFACES — LIGHT ═══════════════════════

  /// Main background
  static const Color surface = Color(0xFFF5F6F8);

  /// Card / elevated surface
  static const Color card = Color(0xFFFFFFFF);

  /// Borders, dividers
  static const Color border = Color(0xFFE4E6EB);

  /// Chip / input fill
  static const Color chip = Color(0xFFF0F1F3);

  /// Header / hero gradient start (warm cream)
  static const Color headerStart = Color(0xFFFFF8F0);

  /// Header / hero gradient end (soft peach)
  static const Color headerEnd = Color(0xFFFFE5D9);

  // ═══════════════════════ SURFACES — DARK ═══════════════════════

  /// Main background — dark
  static const Color surfaceDark = Color(0xFF0F0F1A);

  /// Card / elevated surface — dark
  static const Color cardDark = Color(0xFF1A1A2E);

  /// Secondary dark surface (for gradients)
  static const Color surfaceDark2 = Color(0xFF16213E);

  /// Chip / input fill — dark
  static const Color chipDark = Color(0xFF252540);

  // ═══════════════════════ TEXT ═══════════════════════

  /// Primary text (light mode) — near-black, NOT pure black
  static const Color textDark = Color(0xFF2E2E2E);

  /// Secondary text (light mode)
  static const Color textMuted = Color(0xFF6B7280);

  /// Tertiary / subtle text (light mode)
  static const Color textSubtle = Color(0xFF9CA3AF);

  /// Primary text (dark mode) — off-white
  static const Color textLight = Color(0xFFF5F5F5);

  /// Secondary text (dark mode)
  static const Color textLightMuted = Color(0xFFB0B0C0);

  /// Tertiary text (dark mode)
  static const Color textLightSubtle = Color(0xFF6B6B80);

  // ═══════════════════════ SEMANTIC ═══════════════════════

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ═══════════════════════ UTILITY ═══════════════════════

  /// Shadow base — dark navy for depth
  static const Color shadow = Color(0xFF1A1A2E);

  /// White (icon-on-color, text-on-dark)
  static const Color white = Color(0xFFFFFFFF);

  // ── Backward-compat aliases (used by login/signup — DO NOT REMOVE) ──
  static const Color secondary = headerEnd;

  // ═══════════════════════ THEME-AWARE GETTERS ═══════════════════════
  //
  // Light mode uses the premium palette as-is.
  // Dark mode swaps surfaces & text brightness. Brand colors stay the same.

  static Color background(bool isDark) => isDark ? surfaceDark : surface;
  static Color cardBg(bool isDark) => isDark ? cardDark : card;
  static Color chipBg(bool isDark) => isDark ? chipDark : chip;
  static Color headerGradientStart(bool isDark) =>
      isDark ? cardDark : headerStart;
  static Color headerGradientEnd(bool isDark) =>
      isDark ? surfaceDark2 : headerEnd;

  static Color textPrimary(bool isDark) => isDark ? textLight : textDark;
  static Color textSecondary(bool isDark) => isDark ? textLightMuted : textMuted;
  static Color textTertiary(bool isDark) => isDark ? textLightSubtle : textSubtle;

  // ═══════════════════════ GRADIENTS ═══════════════════════

  /// CTA / button gradient  (#FF7A3D → #FF9A6C)
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, orangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card image overlay — transparent → 60% black
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
    colors: [
      Color(0x00000000),
      Color(0x20000000),
      Color(0x99000000),
    ],
  );

  // ═══════════════════════ ThemeData BUILDERS ═══════════════════════

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.light(
        primary: orange,
        onPrimary: white,
        secondary: orangeSoft,
        onSecondary: textDark,
        surface: card,
        onSurface: textDark,
        error: error,
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: headerStart,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chip,
        selectedColor: orange,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: orange),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: chip,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textMuted),
        labelLarge: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: orange,
        onPrimary: white,
        secondary: orangeSoft,
        onSecondary: textDark,
        surface: cardDark,
        onSurface: textLight,
        error: error,
        outline: chipDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipDark,
        selectedColor: orange,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: orange),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: chipDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: chipDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: chipDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: textLight),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: textLight),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textLight),
        bodyLarge: TextStyle(fontSize: 16, color: textLight),
        bodyMedium: TextStyle(fontSize: 14, color: textLightMuted),
        labelLarge: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textLight),
      ),
    );
  }
}
