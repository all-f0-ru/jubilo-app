import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/jubilo_app_bar.dart';
import 'cuentanos_sobre_ti_screen.dart';
import 'temas_screen.dart';

/// Raíz de la pestaña "Aprender". Si la persona todavía no respondió
/// sexo/edad, muestra un estado vacío invitando a personalizar. Una vez
/// personalizado (guardado en [SettingsProvider], persiste entre
/// pestañas), muestra su situación y recomendaciones.
class TuSituacionScreen extends StatelessWidget {
  const TuSituacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final segmentInfo = settings.segmentInfo;
    final edad = settings.edad;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: jubiloAppBar(context, title: 'Aprender', highContrast: hc),
      body: SafeArea(
        child: segmentInfo == null || edad == null
            ? _EstadoVacio(hc: hc, scale: scale)
            : _EstadoPersonalizado(
                segmentInfo: segmentInfo, edad: edad, hc: hc, scale: scale),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool hc;
  final double scale;

  const _EstadoVacio({required this.hc, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined,
                size: 48, color: hc ? Colors.black45 : AppColors.inkSoft),
            const SizedBox(height: 16),
            Text(
              'Primero cuéntanos tu sexo y edad.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Personalizar mi guía',
              onPressed: () {
                Navigator.of(context).push(
                  JubiloPageRoute(
                      builder: (_) => const CuentanosSobreTiScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoPersonalizado extends StatelessWidget {
  final UserSegmentInfo segmentInfo;
  final int edad;
  final bool hc;
  final double scale;

  const _EstadoPersonalizado({
    required this.segmentInfo,
    required this.edad,
    required this.hc,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final recomendaciones = recomendacionesPara(segmentInfo.segmento);
    final accent = hc ? Colors.black : AppColors.teal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TU SEGMENTO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  )),
              const SizedBox(height: 6),
              Text('${segmentInfo.etapa} · $edad años',
                  style: AppTextStyles.heading(scale, color: Colors.white)),
              const SizedBox(height: 8),
              Text(segmentInfo.mensaje,
                  style: AppTextStyles.body(scale,
                      color: Colors.white.withValues(alpha: 0.92))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        JubiloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edad legal de jubilación',
                  style: AppTextStyles.heading(scale * 0.78,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 6),
              Text('${segmentInfo.edadLegal} años',
                  style: AppTextStyles.display(scale * 0.6,
                      color: hc ? Colors.black : AppColors.tealDeep)),
              const SizedBox(height: 6),
              Text(
                'La edad legal de jubilación para '
                '${segmentInfo.edadLegal == 60 ? "mujeres" : "hombres"} es '
                '${segmentInfo.edadLegal} años.',
                style: AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
              ),
            ],
          ),
        ),

        if (segmentInfo.mostrarAvisoNoObligacion) ...[
          const SizedBox(height: 16),
          InfoBanner(
            variant: BannerVariant.warning,
            fontScale: scale,
            text: 'Importante: Cumplir la edad legal no significa que '
                'estés obligado/a a jubilarte. Puedes seguir trabajando y '
                'cotizando para mejorar tu pensión.',
          ),
        ],
        const SizedBox(height: 24),

        Text('Recomendaciones para ti',
            style: AppTextStyles.heading(scale * 0.85, color: hc ? Colors.black : null)),
        const SizedBox(height: 12),
        for (int i = 0; i < recomendaciones.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JubiloCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(recomendaciones[i],
                        style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        PrimaryButton(
          label: 'Ver temas para mi etapa',
          icon: Icons.arrow_forward_rounded,
          trailingIcon: true,
          onPressed: () {
            Navigator.of(context).push(
              JubiloPageRoute(
                builder: (_) => TemasScreen(segmentInfo: segmentInfo),
              ),
            );
          },
        ),
      ],
    );
  }
}
