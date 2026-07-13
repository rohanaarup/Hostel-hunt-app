import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // PRIMARY — Auburn
  static const Color auburn50 = Color(0xFFF9E6E6);
  static const Color auburn100 = Color(0xFFF0C9C9);
  static const Color auburn300 = Color(0xFFC97A7A);
  static const Color auburn500 = Color(0xFFA52A2A); // BASE
  static const Color auburn700 = Color(0xFF7B1F1F);
  static const Color auburn900 = Color(0xFF4A1212);

  // SECONDARY — Warm Ivory
  static const Color ivory50 = Color(0xFFFDFBF8);
  static const Color ivory100 = Color(0xFFF7EFEA); // BASE bg/card
  static const Color ivory300 = Color(0xFFE8DDD1);
  static const Color ivory500 = Color(0xFFC4B7A6);
  static const Color ivory700 = Color(0xFF6B5D4F);
  static const Color ivory900 = Color(0xFF2E2723);

  // TERTIARY — Deep Emerald
  static const Color emerald300 = Color(0xFF5FA394);
  static const Color emerald500 = Color(0xFF0A6A5A); // BASE
  static const Color emerald700 = Color(0xFF06463B);

  // INK
  static const Color ink900 = Color(0xFF1E1B1B);
  static const Color ink700 = Color(0xFF5A3D34);
  static const Color ink50 = Color(0xFFF7EFEA);

  // QUATERNARY — Terracotta Ember (NEW)
  static const Color ember300 = Color(0xFFD98B6B);
  static const Color ember500 = Color(0xFFB85C38); // BASE
  static const Color ember700 = Color(0xFF8B3A22);
  static const Color ember900 = Color(0xFF5C2414);

  // SEMANTIC
  static const Color success = emerald500;
  static const Color error = Color(0xFF8C2F2F);
  static const Color warning = Color(0xFFB8843A);

  // UTILITY
  static const Color white = Color(0xFFFFFFFF);
  static const Color shadow = ink900;

  // COMPONENT GETTERS (Light & Dark logic built-in to adhere to cross-family rules)
  static Color appBackground(bool isDark) => isDark ? ink900 : ivory50;
  static Color appBarBackground(bool isDark) => isDark ? ink900 : ivory50;
  static Color appBarTitle(bool isDark) => isDark ? ivory50 : ink900;
  
  static Color bottomNavBg(bool isDark) => isDark ? ivory900 : ivory100;
  static Color bottomNavActive(bool isDark) => isDark ? auburn300 : auburn500;
  // FIX: Dark mode inactive was ivory500 on ivory900 (same family). Changed to ink50.withValues(alpha: 0.7)
  static Color bottomNavInactive(bool isDark) => isDark ? ink50.withValues(alpha: 0.7) : ink700;

  static Color buttonPrimaryBg(bool isDark) => isDark ? auburn300 : auburn500;
  static Color buttonPrimaryText(bool isDark) => isDark ? ink900 : ivory50;
  static Color buttonSecondaryBg(bool isDark) => isDark ? ivory700 : ivory300;
  static Color buttonSecondaryText(bool isDark) => isDark ? ivory50 : ink700;
  static Color buttonOutline(bool isDark) => isDark ? auburn300 : auburn500;
  static Color buttonDisabledBg(bool isDark) => isDark ? ivory900 : ivory100;
  // FIX: Dark mode disabled text on ivory900 bg was ivory500 (same family). Changed to ink50.withValues(alpha: 0.5)
  static Color buttonDisabledText(bool isDark) => isDark ? ink50.withValues(alpha: 0.5) : ivory500;

  static Color cardBg(bool isDark) => isDark ? ivory900 : ivory100;
  static Color cardBorder(bool isDark) => isDark ? ivory700 : ivory300;
  static Color divider(bool isDark) => isDark ? ivory700 : ivory300;

  static Color textHeading(bool isDark) => isDark ? ivory50 : ink900;
  static Color textBody(bool isDark) => isDark ? ivory100 : ink900;
  // Body text strictly inside cards (ivory900 bg) must be ink50 to avoid ivory-on-ivory
  static Color textBodyOnCard(bool isDark) => isDark ? ink50 : ink900;
  static Color textSecondary(bool isDark) => isDark ? ivory500 : ink700;
  // Secondary text strictly inside cards (ivory900 bg) must be from a different family
  static Color textSecondaryOnCard(bool isDark) => isDark ? ink50.withValues(alpha: 0.7) : ink700;
  static Color textPrice(bool isDark) => isDark ? auburn300 : auburn700;
  static Color textLink(bool isDark) => isDark ? auburn300 : auburn500;

  static Color badgeVerifiedBg(bool isDark) => isDark ? emerald700 : emerald300;
  static Color badgeVerifiedText(bool isDark) => isDark ? emerald300 : emerald700;
  static Color chipInactiveBg(bool isDark) => isDark ? ivory700 : ivory300;
  // FIX: Dark inactive chip text was ivory300 on ivory700 (same family). Changed to ink50
  static Color chipInactiveText(bool isDark) => isDark ? ink50 : ink700;
  static Color chipActiveBg(bool isDark) => isDark ? auburn300 : auburn500;
  static Color chipActiveText(bool isDark) => isDark ? ink900 : ivory50;

  static Color inputBg(bool isDark) => isDark ? ivory900 : ivory50;
  static Color inputBorder(bool isDark) => isDark ? ivory700 : ivory300;
  static Color inputBorderFocus(bool isDark) => isDark ? auburn300 : auburn500;
  // FIX: Dark label text on ivory900 was ivory500 (same family). Changed to ink50.withValues(alpha: 0.7)
  static Color inputLabel(bool isDark) => isDark ? ink50.withValues(alpha: 0.7) : ink700;

  static Color toastSuccessBg(bool isDark) => isDark ? emerald700 : emerald300;
  static Color toastSuccessText(bool isDark) => isDark ? emerald300 : emerald700;

  // GRADIENTS
  static const LinearGradient auburnGradient = LinearGradient(
    colors: [auburn500, auburn300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  // THEMEDATA
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: ivory50,
      colorScheme: const ColorScheme.light(
        primary: auburn500,
        onPrimary: ivory50,
        secondary: ivory300,
        onSecondary: ivory700,
        surface: ivory100, // Cards & Surfaces
        onSurface: ink900,
        error: error,
        onError: ivory50,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory50,
        foregroundColor: ink900,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ivory100,
        selectedItemColor: auburn500,
        unselectedItemColor: ink700,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: auburn500,
          foregroundColor: ivory50,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: auburn500,
          side: const BorderSide(color: auburn500, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: auburn500),
      ),
      cardTheme: CardThemeData(
        color: ivory100,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ivory300, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ivory50,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ivory50,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: ivory300,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ivory50,
        labelStyle: const TextStyle(color: ink700),
        hintStyle: const TextStyle(color: ivory500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ivory300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ivory300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: auburn500, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink900),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink900),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink900),
        bodyLarge: TextStyle(fontSize: 16, color: ink900),
        bodyMedium: TextStyle(fontSize: 14, color: ink900),
        bodySmall: TextStyle(fontSize: 12, color: ink700),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink900),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: ink900,
      colorScheme: const ColorScheme.dark(
        primary: auburn300, // Brighten accent colors slightly
        onPrimary: ink900,
        secondary: ivory700,
        onSecondary: ivory50,
        surface: ivory900, // Elevated = lighter
        onSurface: ink50, // Contrast minimum - cross family fix (ink on ivory)
        error: error,
        onError: ivory50,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink900,
        foregroundColor: ivory50,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ivory900,
        selectedItemColor: auburn300,
        // FIX: was ivory500 (same family), changed to ink50 with alpha
        unselectedItemColor: ink50.withValues(alpha: 0.7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: auburn300,
          foregroundColor: ink900,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: auburn300,
          side: const BorderSide(color: auburn300, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: auburn300),
      ),
      cardTheme: CardThemeData(
        color: ivory900,
        elevation: 0, // Elevation = lighter, not shadow.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ivory700, width: 1), // Border replaces shadow
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ivory900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: ivory700, width: 1), // Border replaces shadow
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ivory900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: ivory700, width: 1), // Border replaces shadow
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ivory700,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ivory900,
        // FIX: was ivory500 on ivory900 bg (same family). Changed to ink50 with alpha.
        labelStyle: TextStyle(color: ink50.withValues(alpha: 0.7)),
        hintStyle: const TextStyle(color: ivory500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ivory700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ivory700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: auburn300, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ivory50),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ivory50),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ivory50),
        bodyLarge: TextStyle(fontSize: 16, color: ivory100),
        bodyMedium: TextStyle(fontSize: 14, color: ivory100),
        bodySmall: TextStyle(fontSize: 12, color: ivory500),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ivory50),
      ),
    );
  }
}
