import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Naranja y Azul
  static const Color primary = Color(0xFFFF6B35); // Naranja principal
  static const Color primaryLight = Color(0xFFFF8C42); // Naranja claro
  static const Color primaryDark = Color(0xFFE55A2B); // Naranja oscuro

  static const Color secondary = Color(0xFF1E88E5); // Azul principal
  static const Color secondaryLight = Color(0xFF42A5F5); // Azul claro
  static const Color secondaryDark = Color(0xFF1565C0); // Azul oscuro

  // Colores complementarios
  static const Color accent = Color(0xFFFFAB40); // Naranja acento
  static const Color blueAccent = Color(0xFF64B5F6); // Azul acento

  // Retrocompatibilidad (deprecated - usar primary/secondary)
  @Deprecated('Use AppColors.primary instead')
  static const Color copper = primary;
  @Deprecated('Use AppColors.primaryLight instead')
  static const Color bronzeLight = primaryLight;
  @Deprecated('Use AppColors.primaryDark instead')
  static const Color bronzeDark = primaryDark;
  @Deprecated('Use AppColors.accent instead')
  static const Color orangeAccent = accent;
  @Deprecated('Use AppColors.primaryLight instead')
  static const Color orangeLight = primaryLight;
  @Deprecated('Use AppColors.secondary instead')
  static const Color blueDark = secondary;
  @Deprecated('Use AppColors.secondaryLight instead')
  static const Color blueLight = secondaryLight;

  // Colores neutrales
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color darkGrey = Color(0xFF333333);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color veryLightGrey = Color(0xFFF5F5F5);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFf44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}
