import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const forest = Color(0xFF11302A);
  static const forestDeep = Color(0xFF071612);
  static const forestSoft = Color(0xFFEEF4F1);
  static const ivory = Color(0xFFF8F4EB);
  static const ivoryDark = Color(0xFFEFE7D6);
  static const brass = Color(0xFFB8893B);
  static const brassLight = Color(0xFFE2C48A);
  static const clay = Color(0xFFB5603F);
  static const ink = Color(0xFF1C2420);
  static const inkSoft = Color(0xFF4B5650);
  static const inkMute = Color(0xFF7A847F);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      secondary: AppColors.brass,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.ivory,
  );
  final text = GoogleFonts.manropeTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.forest);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: AppColors.forest.withOpacity(.15)),
  );
  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: GoogleFonts.fraunces(fontSize: 30, fontWeight: FontWeight.w500, color: AppColors.forest),
      headlineMedium: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.forest),
      headlineSmall: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.forest),
      titleLarge: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.forest),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.ivory,
      foregroundColor: AppColors.forest,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.forest),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.forest.withOpacity(.07)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.ivory,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: AppColors.forest.withOpacity(.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.brassLight.withOpacity(.45),
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600)),
    ),
  );
}
