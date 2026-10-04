import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'simulador_preguntas_screen.dart';

/// 1️⃣1️⃣ Intro del simulador: explica qué hace y, muy importante, deja
/// claro desde el principio que es una simulación orientativa/educativa,
/// no un cálculo oficial.
class SimuladorIntroScreen extends StatelessWidget {
  const SimuladorIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Simular mi pensión',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.calculate_outlined,
                  size: 56, color: hc ? Colors.black : AppColors.coral),
              const SizedBox(height: 20),
              Text(
                'Conoce las 4 formas de recibir tu pensión',
                style: AppTextStyles.heading(scale,
                    color: hc ? Colors.black : null),
              ),
              const SizedBox(height: 12),
              Text(
                'Responde 4 preguntas simples (edad, sexo, estado civil e '
                'hijos) y te mostramos las 4 modalidades de pensión que '
                'existen en Chile, para que entiendas cómo funciona cada '
                'una.',
                style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
              ),
              const SizedBox(height: 24),
              InfoBanner(
                variant: BannerVariant.info,
                fontScale: scale,
                text: 'Esta es una simulación orientativa y educativa. No '
                    'reemplaza el cálculo oficial de tu AFP ni una '
                    'compañía de seguros.',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Comenzar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SimuladorPreguntasScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
