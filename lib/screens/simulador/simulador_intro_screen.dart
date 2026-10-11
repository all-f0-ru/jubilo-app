import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/jubilo_app_bar.dart';
import 'simulador_preguntas_screen.dart';

const _temasConsultados = [
  'Tu edad',
  'Tu sexo',
  'Tu estado civil',
  'Si tienes hijos',
];

/// Raíz de la pestaña "Simular": explica qué hace el simulador y deja
/// claro, desde antes de empezar, que es una simulación orientativa y
/// educativa, no un cálculo oficial.
class SimuladorIntroScreen extends StatelessWidget {
  const SimuladorIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final color = hc ? Colors.black : AppColors.coral;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: jubiloAppBar(context, title: 'Simular', highContrast: hc),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.calculate_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Simulador educativo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading(scale, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4 preguntas simples para orientarte sobre las '
                    'modalidades de pensión.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(scale,
                        color: Colors.white.withValues(alpha: 0.92)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Esta es una simulación educativa y orientativa, no '
                  'un cálculo real de tu pensión. Para un monto exacto, '
                  'consulta a tu AFP.',
            ),
            const SizedBox(height: 24),

            Text('Te preguntaremos sobre:',
                style: AppTextStyles.heading(scale * 0.8,
                    color: hc ? Colors.black : null)),
            const SizedBox(height: 10),
            ..._temasConsultados.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hc ? Colors.black : AppColors.inkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(t,
                        style: AppTextStyles.body(scale,
                            color: hc ? Colors.black87 : null)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 28),

            PrimaryButton(
              label: 'Empezar simulación',
              icon: Icons.arrow_forward_rounded,
              trailingIcon: true,
              onPressed: () {
                Navigator.of(context).push(
                  JubiloPageRoute(
                    builder: (_) => const SimuladorPreguntasScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
