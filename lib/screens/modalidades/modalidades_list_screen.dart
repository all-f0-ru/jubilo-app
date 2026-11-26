import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/jubilo_app_bar.dart';
import 'modalidad_detail_screen.dart';

/// Pestaña "Modalidades": lista siempre accesible de las 4 modalidades
/// de pensión que existen en Chile, independiente del Simulador (antes
/// solo aparecían como resultado de responder las 4 preguntas).
/// Modalidades combinadas: función Premium.
bool _esPremium(String id) =>
    id == 'renta_temporal_vitalicia_diferida' ||
    id == 'renta_vitalicia_con_retiro_programado';

class ModalidadesListScreen extends StatelessWidget {
  const ModalidadesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: jubiloAppBar(context, title: 'Alternativas', highContrast: hc),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Alternativas para recibir tu pensión',
                style: AppTextStyles.heading(scale, color: hc ? Colors.black : null)),
            const SizedBox(height: 8),
            Text(
              'Al jubilarte eliges cómo recibir tu pensión. Toca cada una '
              'para ver el detalle.',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 16),
            ...modalidadesPension.map((m) {
              final color = hc ? Colors.black : m.color;
              return FadeSlideIn(
                index: modalidadesPension.indexOf(m),
                child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: JubiloCard(
                  onTap: () {
                    Navigator.of(context).push(
                      JubiloPageRoute(
                        builder: (_) => ModalidadDetailScreen(modalidad: m),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: m.icono, color: color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_esPremium(m.id)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hc ? Colors.black : AppColors.coral,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('PREMIUM',
                                    style: AppTextStyles.small(scale * 0.85,
                                            color: Colors.white)
                                        .copyWith(
                                            fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(m.nombre,
                                style: AppTextStyles.heading(scale * 0.78,
                                        color: hc ? Colors.black : null)
                                    .copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(m.resumen,
                                style: AppTextStyles.small(scale,
                                    color: hc ? Colors.black54 : null)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: hc ? Colors.black : AppColors.inkSoft),
                    ],
                  ),
                ),
              ));
            }),
          ],
        ),
      ),
    );
  }
}
