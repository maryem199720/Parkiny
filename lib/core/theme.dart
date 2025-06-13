import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.backgroundColor,

  // AppBar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textColor,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textColor,
    ),
  ),

  // Text Theme
  textTheme: GoogleFonts.robotoTextTheme().copyWith(
    headlineLarge: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textColor,
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textColor,
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textColor,
    ),
    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textColor,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      color: AppColors.textColor,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      color: AppColors.subtitleColor,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      color: AppColors.subtitleColor,
    ),
  ),

  // Card Theme
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: AppColors.whiteColor,
    shadowColor: AppColors.primaryColor.withOpacity(0.1),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.whiteColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      elevation: 2,
    ),
  ),

  // Outlined Button Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      textStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),

  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      textStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
  ),

  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.whiteColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
    ),
    labelStyle: GoogleFonts.roboto(
      color: AppColors.subtitleColor,
      fontSize: 14,
    ),
    hintStyle: GoogleFonts.roboto(
      color: AppColors.subtitleColor,
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.whiteColor,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.subtitleColor,
    selectedLabelStyle: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),

  // Floating Action Button Theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.whiteColor,
    elevation: 4,
    shape: CircleBorder(),
  ),

  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.accentLightColor,
    labelStyle: GoogleFonts.roboto(
      color: AppColors.textColor,
      fontSize: 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),

  // Dialog Theme
  dialogTheme: DialogTheme(
    backgroundColor: AppColors.whiteColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textColor,
    ),
    contentTextStyle: GoogleFonts.roboto(
      fontSize: 14,
      color: AppColors.subtitleColor,
    ),
  ),

  // Snackbar Theme
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.textColor,
    contentTextStyle: GoogleFonts.roboto(
      color: AppColors.whiteColor,
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  useMaterial3: true,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.darkBackgroundColor,

  // AppBar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.whiteColor,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.whiteColor,
    ),
  ),

  // Text Theme
  textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
    headlineLarge: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.whiteColor,
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.whiteColor,
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.whiteColor,
    ),
    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.whiteColor,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      color: AppColors.whiteColor,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      color: AppColors.accentLightColor,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      color: AppColors.accentLightColor,
    ),
  ),

  // Card Theme
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: AppColors.primaryDarkColor,
    shadowColor: Colors.black.withOpacity(0.3),
  ),

  useMaterial3: true,
);

