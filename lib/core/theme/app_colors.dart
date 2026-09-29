import 'package:flutter/material.dart';

/// Colores oficiales de la identidad visual de Jubilo.
/// Ver: jubilo-identidad-visual.pdf (paleta y tipografía).
class AppColors {
  AppColors._();

  // Modo claro
  static const Color cream = Color(0xFFFDFBF5);
  static const Color creamDeep = Color(0xFFF3EEE1);
  static const Color teal = Color(0xFF1B5E63);
  static const Color tealDeep = Color(0xFF123F43);
  static const Color coral = Color(0xFFD96B3A);
  static const Color coralDeep = Color(0xFFB44F24);
  static const Color ink = Color(0xFF23262B);
  static const Color inkSoft = Color(0xFF55595E);

  static const Color success = Color(0xFF2F7A4F);
  static const Color error = Color(0xFFB23B3B);

  // Modo alto contraste (definido en el prompt de Figma, sección
  // de accesibilidad transversal)
  static const Color contrastBg = Color(0xFFFFFFFF);
  static const Color contrastFg = Color(0xFF000000);
}
