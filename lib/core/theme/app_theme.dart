import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Construye el ThemeData de Jubilo a partir del nivel de escala de fuente
/// activo. Hay dos variantes: la normal (claro) y alto contraste, ambas
/// definidas en el prompt de Figma como temas separados (no solo invertir
/// colores).
class AppTheme {
  AppTheme._();

  static ThemeData light(double fontScale) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.coral,
        surface: AppColors.cream,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(fontScale),
        titleLarge: AppTextStyles.heading(fontScale),
        bodyLarge: AppTextStyles.body(fontScale),
        bodySmall: AppTextStyles.small(fontScale),
        labelLarge: AppTextStyles.button(fontScale, color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button(fontScale),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coralDeep,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.coral, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button(fontScale, color: AppColors.coralDeep),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.creamDeep,
        ),
      ),
    );
  }

  static ThemeData highContrast(double fontScale) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.contrastBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        primary: Colors.black,
        secondary: AppColors.coralDeep,
        surface: Colors.white,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(fontScale, color: Colors.black),
        titleLarge: AppTextStyles.heading(fontScale, color: Colors.black),
        bodyLarge: AppTextStyles.body(fontScale, color: Colors.black),
        bodySmall: AppTextStyles.small(fontScale, color: Colors.black87),
        labelLarge: AppTextStyles.button(fontScale, color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button(fontScale),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Colors.black, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button(fontScale, color: Colors.black),
        ),
      ),
    );
  }
}
