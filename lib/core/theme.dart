
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

final lightTheme = ThemeData(
brightness: Brightness.light,
primaryColor: AppColors.primaryColor,
scaffoldBackgroundColor: AppColors.backgroundColor,
appBarTheme: AppBarTheme(
backgroundColor: AppColors.primaryColor,
foregroundColor: AppColors.whiteColor,
elevation: 0,
),
textTheme: GoogleFonts.poppinsTextTheme().copyWith(
titleLarge: GoogleFonts.poppins(
fontSize: 20,
fontWeight: FontWeight.bold,
color: AppColors.textColor,
),
bodyMedium: GoogleFonts.poppins(
fontSize: 16,
color: AppColors.subtitleColor,
),
),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
padding: EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
),
),
inputDecorationTheme: InputDecorationTheme(
filled: true,
fillColor: AppColors.grayColor,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(8),
borderSide: BorderSide.none,
),
labelStyle: GoogleFonts.poppins(color: AppColors.subtitleColor),
),
bottomNavigationBarTheme: BottomNavigationBarThemeData(
backgroundColor: AppColors.whiteColor,
selectedItemColor: AppColors.secondaryColor,
unselectedItemColor: AppColors.subtitleColor,
selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
),
useMaterial3: true,
);
