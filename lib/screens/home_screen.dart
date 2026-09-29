import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/jubilo_widgets.dart';
import 'settings_screen.dart';

/// 5️⃣ Inicio (home). Los dos flujos (Aprender / Simular) todavía son
/// solo un aviso "Próximamente" — se conectan de verdad a partir de la
/// Reunión 5 en adelante, según el plan de trabajo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context, String flujo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$flujo: se conecta en una próxima reunión')),
    );
  }

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
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(Icons.wb_sunny_rounded,
              color: highContrast ? Colors.black : AppColors.coral),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: highContrast ? Colors.black : AppColors.tealDeep),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                '¿Qué quieres hacer hoy?',
                textAlign: TextAlign.center,
                style: AppTextStyles.display(
                  scale * 0.7,
                  color: highContrast ? Colors.black : null,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Aprender sobre mi pensión',
                onPressed: () => _comingSoon(context, 'Aprender'),
              ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: 'Simular mi pensión',
                onPressed: () => _comingSoon(context, 'Simulador'),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => _comingSoon(context, 'Ayuda'),
                  child: Text(
                    'Ayuda',
                    style: AppTextStyles.small(
                      scale,
                      color: highContrast ? Colors.black54 : null,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
