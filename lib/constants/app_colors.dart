// lib/constants/app_colors.dart

import 'package:flutter/material.dart';

/// Application color palette for consistent UI
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFF5EBBB7);
  static const Color secondaryDark = Color(0xFF006B5B);
  
  // Accent colors
  static const Color accent = Color(0xFFFFC107);
  static const Color accentLight = Color(0xFFFFF350);
  static const Color accentDark = Color(0xFFC79100);
  
  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Schedule colors
  static const List<Color> scheduleColors = [
    Color(0xFF6200EE), // Purple
    Color(0xFF03DAC6), // Teal
    Color(0xFF018786), // Dark Teal
    Color(0xFFB00020), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Deep Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
  ];

  // Get a schedule color by index with wrapping
  static Color getScheduleColor(int index) {
    return scheduleColors[index % scheduleColors.length];
  }

  // Create a color with transparency
  // This method works with any Flutter version and avoids deprecated methods
  static Color withOpacity(Color color, double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    
    final int alpha = (opacity * 255).round();
    return Color.fromARGB(alpha, color.red, color.green, color.blue);
  }
  
  // Lighten a color by a percentage (amount between 0 and 1)
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    
    return hsl.withLightness(lightness).toColor();
  }
  
  // Darken a color by a percentage (amount between 0 and 1)
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    
    return hsl.withLightness(lightness).toColor();
  }

  // Convert color to material color
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
  
  // Determine if a color is light (useful for choosing contrasting text colors)
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
  
  // Choose a contrasting text color (black or white) based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? textPrimary : Colors.white;
  }
}