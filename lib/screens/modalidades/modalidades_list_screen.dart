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
class ModalidadesListScreen extends StatelessWidget {
  const ModalidadesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: jubiloAppBar(context, title: 'Modalidades', highContrast: hc),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Las 4 modalidades de pensión',
                style: AppTextStyles.heading(scale, color: hc ? Colors.black : null)),
            const SizedBox(height: 8),
            Text(
              'Al jubilarte eliges cómo recibir tu pensión. Toca cada una '
              'para ver el detalle.',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 20),
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
                            Text(m.nombre,
                                style: AppTextStyles.heading(scale * 0.78,
                                    color: hc ? Colors.black : null)),
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
