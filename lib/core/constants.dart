import 'package:flutter/material.dart';

class AppColors {
  // Enhanced Primary Palette

  static const primaryExtraLight = Color(0xFFE1BEE7); // Very light purple
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
  // Enhanced Accent PaletteModern dark
  static const cardBackgroundColor = Color(0xFFFFFFFF); // Pure white for cards
  static const surfaceColor = Color(0xFFF5F5F7); // Apple-like surface

  // Enhanced Text Colors

  static const textSecondaryColor = Color(0xFF4A4A4A); // Medium gray

  static const textLightColor = Color(0xFFB0B0B0); // Very light text

  // Modern Status Colors
  //static const errorColor = Color(0xFFFF3B30); // iOS red
  //static const successColor = Color(0xFF34C759); // iOS green
  static const warningColor = Color(0xFFFF9500); // iOS orange
  static const infoColor = Color(0xFF007AFF); // iOS blue

  // Additional Modern Colors
  static const borderColor = Color(0xFFE5E5EA); // Subtle borders

  // Gradient Colors
  static const gradientStart = Color(0xFF667eea);
  static const gradientEnd = Color(0xFF764ba2);

  // Shadow Colors
  static const shadowLight = Color(0x1A000000); // 10% black
  static const shadowMedium = Color(0x33000000); // 20% black
  static const shadowDark = Color(0x4D000000); // 30% black



  static const Color accentColor = Color(0xFFFFCA28); // Gold for icons

}

class AppIcons {
  static const reservation = Icons.receipt_long;
  static const scan = Icons.camera_alt;
  static const vehicle = Icons.directions_car;
  static const profile = Icons.person;
  static const parking = Icons.local_parking;
  static const help = Icons.help;
  static const location = Icons.location_on;
  static const time = Icons.access_time;
  static const search = Icons.search;
  static const filter = Icons.filter_list;
  static const favorite = Icons.favorite;
  static const settings = Icons.settings;
  static const notification = Icons.notifications;
  static const map = Icons.map;
}

class AppSizes {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 50.0;

  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Font Sizes
  static const double fontXs = 12.0;
  static const double fontSm = 14.0;
  static const double fontMd = 16.0;
  static const double fontLg = 18.0;
  static const double fontXl = 20.0;
  static const double fontXxl = 24.0;
  static const double fontTitle = 28.0;
  static const double fontDisplay = 32.0;
}

class AppShadows {
  static const BoxShadow light = BoxShadow(
    color: AppColors.shadowLight,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: AppColors.shadowMedium,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow heavy = BoxShadow(
    color: AppColors.shadowDark,
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.secondaryColor, AppColors.accentDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.successColor, Color(0xFF28A745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient background = LinearGradient(
    colors: [AppColors.backgroundColor, AppColors.surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

