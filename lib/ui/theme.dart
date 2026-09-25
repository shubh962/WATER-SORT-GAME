import 'package:flutter/material.dart';

class AppColors {
  static const Color bgTop = Color(0xFF1B2350);
  static const Color bgMid = Color(0xFF0C1024);
  static const Color bgBottom = Color(0xFF080A18);
  static const Color panel = Color(0xFF1E2559);
  static const Color panelBorder = Color(0xFF3A4A94);
  static const Color teal = Color(0xFF37D3C2);
  static const Color green = Color(0xFF7BE04A);
  static const Color purple = Color(0xFFA06BFF);
  static const Color gold = Color(0xFFFFD23F);
  static const Color red = Color(0xFFFF5C7A);
  static const Color text = Color(0xFFEAF6FF);
  static const Color textDim = Color(0xFF9FB4E8);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.dark,
    surface: AppColors.bgMid,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Fredoka',
    scaffoldBackgroundColor: AppColors.bgMid,
    textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Fredoka',
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.panel,
      contentTextStyle: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.panelBorder, width: 2),
      ),
    ),
  );
}

const TextStyle kTitle = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.text);
const TextStyle kBody = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.text);
const TextStyle kDim = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textDim);

BoxDecoration panelDecoration({double radius = 20}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF232B63), Color(0xFF161B45)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.panelBorder, width: 2),
    );
