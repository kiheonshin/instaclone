import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Instagram 스타일의 앱 테마 (Stitch MCP 디자인 기반)
class AppTheme {
  AppTheme._();

  // Instagram 브랜드 컬러
  static const Color instagramPurple = Color(0xFF833AB4);
  static const Color instagramRed = Color(0xFFFD1D1D);
  static const Color instagramOrange = Color(0xFFF77737);
  static const Color instagramYellow = Color(0xFFFCAF45);
  static const Color instagramBlue = Color(0xFF0095F6);
  static const Color stitchBlue = Color(0xFF137FEC); // Stitch 디자인 accent
  static const Color instagramLikeRed = Color(0xFFED4956);

  // 라이트 테마 컬러
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF262626);
  static const Color lightSecondaryText = Color(0xFF8E8E8E);
  static const Color lightBorder = Color(0xFFDBDBDB);

  // 다크 테마 컬러 (HTML 디자인: background-dark #101922)
  static const Color darkBg = Color(0xFF101922);
  static const Color darkCardBg = Color(0xFF1A242D);
  static const Color darkPrimaryText = Color(0xFFF5F5F5);
  static const Color darkSecondaryText = Color(0xFFA8A8A8);
  static const Color darkBorder = Color(0xFF262626);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: lightBg,
        onSurface: lightPrimaryText,
        primary: stitchBlue,
        onPrimary: Colors.white,
        secondary: instagramPurple,
        outline: lightBorder,
      ),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightPrimaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCardBg,
        selectedItemColor: lightPrimaryText,
        unselectedItemColor: lightSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: stitchBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: stitchBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: stitchBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimaryText,
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: stitchBlue,
        ),
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: lightPrimaryText,
          ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightPrimaryText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightPrimaryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightPrimaryText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: lightSecondaryText,
        ),
      ),
      ),
      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: darkBg,
        onSurface: darkPrimaryText,
        primary: stitchBlue,
        onPrimary: Colors.white,
        secondary: instagramPurple,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkPrimaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: darkPrimaryText,
        unselectedItemColor: darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkSecondaryText, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: stitchBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: stitchBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryText,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: stitchBlue,
        ),
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: darkPrimaryText,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkPrimaryText,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkPrimaryText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: darkPrimaryText,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: darkSecondaryText,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Instagram 그라데이션 로고용 도형
  static BoxDecoration get instagramGradientBox => const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            instagramPurple,
            instagramRed,
            instagramOrange,
            instagramYellow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}
