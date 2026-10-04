import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

class _Paso {
  final String titulo;
  final String descripcion;
  const _Paso(this.titulo, this.descripcion);
}

const List<_Paso> _pasos = [
  _Paso(
    'Revisa tu ahorro',
    'Entra al sitio o app de tu AFP con tu clave única y pide tu '
        'Certificado de Saldo, para saber cuánto llevas ahorrado.',
  ),
  _Paso(
    'Compara tus opciones',
    'Pide a tu AFP ofertas de pensión en las distintas modalidades, para '
        'comparar cuánto recibirías en cada una.',
  ),
  _Paso(
    'Revisa beneficios adicionales',
    'Pregunta por la PGU, el Bono por Hijo y otros beneficios del Estado '
        'que podrían sumarse a tu pensión.',
  ),
  _Paso(
    'Elige tu modalidad',
    'Con la información comparada, elige la modalidad de pensión que '
        'mejor se ajuste a tu situación.',
  ),
  _Paso(
    'Solicita tu pensión',
    'Firma la solicitud con tu AFP (o la compañía de seguros, según la '
        'modalidad elegida) y comienza a recibir tu pensión.',
  ),
];

/// 🔟 "Cómo empezar a jubilarme": la ruta de 5 pasos para iniciar el
/// trámite de pensión, en lenguaje simple.
class ComoEmpezarScreen extends StatelessWidget {
  final UserSegmentInfo segmentInfo;

  const ComoEmpezarScreen({super.key, required this.segmentInfo});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cómo empezar a jubilarme',
            style: AppTextStyles.heading(0.78, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Esta es la ruta general para iniciar tu trámite de '
              'pensión, paso a paso.',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 24),

            for (int i = 0; i < _pasos.length; i++) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (i != _pasos.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pasos[i].titulo,
                              style: AppTextStyles.heading(scale * 0.8,
                                  color: hc ? Colors.black : null),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _pasos[i].descripcion,
                              style: AppTextStyles.body(scale,
                                  color: hc ? Colors.black87 : null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Puedes hacer este trámite tú mismo/a, o pedir ayuda a '
                  'un familiar de confianza en cualquier paso.',
            ),
          ],
        ),
      ),
    );
  }
}
