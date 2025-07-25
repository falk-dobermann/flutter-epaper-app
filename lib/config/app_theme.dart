import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandColor = Color(0xFF006a94);
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: const TextStyle(color: Colors.white),
        toolbarTextStyle: const TextStyle(color: Colors.white),
      )
    );
  }
}
