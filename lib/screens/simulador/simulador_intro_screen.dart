import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/respuestas_encuesta_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/jubilo_app_bar.dart';
import 'simulador_preguntas_screen.dart';
import 'simulador_resultados_screen.dart';

class _TemaConsultado {
  final String texto;
  final IconData icono;
  const _TemaConsultado(this.texto, this.icono);
}

const List<_TemaConsultado> _temasConsultados = [
  _TemaConsultado('Edad', Icons.cake_outlined),
  _TemaConsultado('Sexo', Icons.person_outline),
  _TemaConsultado('Estado civil', Icons.favorite_border_rounded),
  _TemaConsultado('Hijos', Icons.child_care_outlined),
];

/// Etiqueta con ícono que adelanta de qué tratan las preguntas.
class _EtiquetaTema extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool hc;
  final double scale;

  const _EtiquetaTema({
    required this.texto,
    required this.icono,
    required this.hc,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final color = hc ? Colors.black : AppColors.tealDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 8),
          Text(texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16 * scale,
              )),
        ],
      ),
    );
  }
}

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
      appBar: jubiloAppBar(context, title: 'Calcula tu pensión', highContrast: hc),
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

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final t in _temasConsultados)
                  _EtiquetaTema(texto: t.texto, icono: t.icono, hc: hc, scale: scale),
              ],
            ),
            const SizedBox(height: 20),

            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Simulación educativa. Para un monto exacto, consulta a '
                  'tu AFP.',
            ),
            const SizedBox(height: 28),

            if (context.watch<RespuestasEncuestaProvider>().tieneRespuestas) ...[
              _TarjetaEncuestaGuardada(scale: scale, hc: hc),
              const SizedBox(height: 16),
            ],

            PrimaryButton(
              label: context.watch<RespuestasEncuestaProvider>().tieneRespuestas
                  ? 'Cambiar mis respuestas'
                  : 'Empezar simulación',
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

/// Muestra las respuestas que la persona ya dio y deja ir directo a sus
/// resultados, sin repetir la encuesta.
class _TarjetaEncuestaGuardada extends StatelessWidget {
  final double scale;
  final bool hc;

  const _TarjetaEncuestaGuardada({required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RespuestasEncuestaProvider>().respuestas!;
    final color = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      borderColor: color,
      borderWidth: 2,
      onTap: () {
        Navigator.of(context).push(
          JubiloPageRoute(
            builder: (_) => SimuladorResultadosScreen(respuestas: r),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.check_circle_outline_rounded, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Tus respuestas están guardadas',
                    style: AppTextStyles.heading(scale * 0.75,
                        color: hc ? Colors.black : null)),
              ),
              Icon(Icons.arrow_forward_rounded, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(label: r.rangoEdad, color: color),
              AppChip(label: r.sexo, color: color),
              AppChip(label: r.estadoCivil, color: color),
              AppChip(
                  label: r.tieneHijos ? 'Con hijos/as' : 'Sin hijos/as',
                  color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text('Toca para ver tus resultados sin repetir la encuesta.',
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : null)),
        ],
      ),
    );
  }
}
