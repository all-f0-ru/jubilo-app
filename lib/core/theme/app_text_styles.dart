import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Los 3 niveles de tamaño de letra definidos para Jubilo:
/// Normal (100%), Grande (125%) y Muy grande (150%).
/// Ver pantalla "Configuración" y "Ajuste inicial de texto" en el prompt
/// de Figma.
enum FontScaleLevel { normal, grande, muyGrande }

extension FontScaleLevelX on FontScaleLevel {
  double get multiplier {
    switch (this) {
      case FontScaleLevel.normal:
        return 1.0;
      case FontScaleLevel.grande:
        return 1.25;
      case FontScaleLevel.muyGrande:
        return 1.5;
    }
  }

  /// Etiqueta corta para los botones "A / A+ / A++".
  String get label {
    switch (this) {
      case FontScaleLevel.normal:
        return 'A';
      case FontScaleLevel.grande:
        return 'A+';
      case FontScaleLevel.muyGrande:
        return 'A++';
    }
  }
}

/// Estilos de texto de Jubilo, usando Atkinson Hyperlegible (tipografía
/// diseñada para máxima legibilidad en baja visión).
/// Los tamaños base (34 / 24 / 19 / 16px) vienen del prompt de Figma y se
/// multiplican por el [scale] activo del usuario.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(double scale, {Color? color}) =>
      GoogleFonts.atkinsonHyperlegible(
        fontSize: 34 * scale,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.tealDeep,
      );

  static TextStyle heading(double scale, {Color? color}) =>
      GoogleFonts.atkinsonHyperlegible(
        fontSize: 24 * scale,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
      );

  static TextStyle body(double scale, {Color? color}) =>
      GoogleFonts.atkinsonHyperlegible(
        fontSize: 19 * scale,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.ink,
        height: 1.5,
      );

  /// Nunca debe usarse un tamaño menor a este (16px base), incluso en
  /// notas aclaratorias, por la política de accesibilidad del proyecto.
  static TextStyle small(double scale, {Color? color}) =>
      GoogleFonts.atkinsonHyperlegible(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.inkSoft,
      );

  static TextStyle button(double scale, {Color? color}) =>
      GoogleFonts.atkinsonHyperlegible(
        fontSize: 19 * scale,
        fontWeight: FontWeight.w700,
        color: color ?? Colors.white,
      );
}
