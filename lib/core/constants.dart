import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const primaryColor = Color(0xFF6A1B9A); // Primary 500
  static const primaryLightColor = Color(0xFFAB77C2); // Primary 300
  static const primaryDarkColor = Color(0xFF3A0F5A); // Primary 900

  // Accent Palette
  static const secondaryColor = Color(0xFFD4AF37); // Accent 500
  static const accentLightColor = Color(0xFFF9F3D6); // Accent 50
  static const accentDarkColor = Color(0xFF806F1F); // Accent 900

  // Background and Text Colors
  static const backgroundColor = Color(0xFFF5F5F5); // Light Gray for background
  static const darkBackgroundColor = Color(0xFF1E0D2B); // Dark background from frontend
  static const textColor = Color(0xFF1E0D2B); // Dark color for titles
  static const subtitleColor = Color(0xFF757575); // Light Gray for subtitles

  // Status Colors
  static const errorColor = Color(0xFFE57373); // Soft Red
  static const successColor = Color(0xFF81C784); // Light Green

  // Additional Colors (from ReservationPage)
  static const whiteColor = Color(0xFFFFFFFF);
  static const grayColor = Color(0xFFEEEEEE);
  static const pastelPurple = Color(0xFFE9D5FF);
  static const deepPurple = Color(0xFF4A148C);
  static const gold100 = Color(0xFFFDf6E3);
}
class AppIcons {
  static const reservation = Icons.receipt_long;
  static const scan = Icons.camera_alt;
  static const vehicle = Icons.directions_car;
  static const profile = Icons.person;
  static const parking = Icons.local_parking;
  static const help = Icons.help;
}