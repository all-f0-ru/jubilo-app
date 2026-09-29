import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// 1️⃣8️⃣ Configuración: tamaño de letra, alto contraste, lectura en voz
/// alta. Es la misma lógica que se usó en el Ajuste inicial de texto del
/// onboarding, pero accesible en cualquier momento.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final highContrast = settings.highContrast;

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Configuración',
            style: AppTextStyles.heading(1.0,
                color: highContrast ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Tamaño de letra',
                style: AppTextStyles.heading(scale,
                    color: highContrast ? Colors.black : null)),
            const SizedBox(height: 12),
            Row(
              children: FontScaleLevel.values.map((level) {
                final selected = settings.fontScale == level;
                final accent = highContrast ? Colors.black : AppColors.teal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () =>
                          context.read<SettingsProvider>().setFontScale(level),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            selected ? accent : Colors.transparent,
                        foregroundColor: selected ? Colors.white : accent,
                        side:
                            BorderSide(color: accent, width: selected ? 0 : 2),
                      ),
                      child: Text(level.label),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SwitchListTile(
              value: highContrast,
              onChanged: (v) =>
                  context.read<SettingsProvider>().toggleHighContrast(v),
              title: Text('Alto contraste',
                  style: AppTextStyles.body(scale,
                      color: highContrast ? Colors.black : null)),
              subtitle: Text(
                'Colores más marcados, útil con luz muy fuerte o poca visión.',
                style: AppTextStyles.small(scale,
                    color: highContrast ? Colors.black54 : null),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),

            SwitchListTile(
              value: settings.voiceEnabled,
              onChanged: (v) =>
                  context.read<SettingsProvider>().toggleVoice(v),
              title: Text('Lectura en voz alta',
                  style: AppTextStyles.body(scale,
                      color: highContrast ? Colors.black : null)),
              subtitle: Text(
                'Activa el botón "Escuchar" en los contenidos.',
                style: AppTextStyles.small(scale,
                    color: highContrast ? Colors.black54 : null),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
