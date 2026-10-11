import 'package:flutter/material.dart';
import 'jubilo_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../screens/settings_screen.dart';
import '../../screens/ayuda/ayuda_screen.dart';

/// Los 2 accesos que aparecen en la esquina superior derecha de todas
/// las pantallas de Jubilo: Ayuda y Configuración. Se centralizan acá
/// para que las 10+ pantallas que los usan no dupliquen la lógica.
List<Widget> jubiloHeaderActions(BuildContext context,
    {required bool highContrast}) {
  final color = highContrast ? Colors.black : AppColors.tealDeep;
  return [
    IconButton(
      icon: Icon(Icons.help_outline_rounded, color: color),
      tooltip: 'Ayuda',
      onPressed: () => Navigator.of(context).push(
        JubiloPageRoute(builder: (_) => const AyudaScreen()),
      ),
    ),
    IconButton(
      icon: Icon(Icons.settings_outlined, color: color),
      tooltip: 'Configuración',
      onPressed: () => Navigator.of(context).push(
        JubiloPageRoute(builder: (_) => const SettingsScreen()),
      ),
    ),
    const SizedBox(width: 4),
  ];
}

/// AppBar estándar de Jubilo: título simple + los accesos de arriba.
/// Para Inicio (que tiene su propio encabezado con logo) no se usa este
/// helper, pero sí [jubiloHeaderActions] directamente.
PreferredSizeWidget jubiloAppBar(
  BuildContext context, {
  required String title,
  required bool highContrast,
  Widget? leading,
  double titleScale = 0.85,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: leading,
    title: Text(title,
        style: AppTextStyles.heading(titleScale,
            color: highContrast ? Colors.black : null)),
    actions: jubiloHeaderActions(context, highContrast: highContrast),
  );
}
