import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/models/topic.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'contenido_tema_screen.dart';
import 'como_empezar_screen.dart';

/// 8️⃣ "Temas personalizados": lista de los 7 temas centrales, ordenados
/// dejando primero los más relevantes para el segmento de la persona
/// (sin ocultar el resto, para que igual pueda explorar todo).
class TemasScreen extends StatelessWidget {
  final UserSegmentInfo segmentInfo;

  const TemasScreen({super.key, required this.segmentInfo});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final temas = temasOrdenadosPorSegmento(segmentInfo.segmento);

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Temas para ti',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Elige un tema para aprender más. Destacamos primero los '
              'más útiles para tu etapa (${segmentInfo.etapa.toLowerCase()}).',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 20),

            // Acceso directo a la ruta de 5 pasos para empezar a jubilar.
            _RouteCard(
              scale: scale,
              highContrast: hc,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ComoEmpezarScreen(segmentInfo: segmentInfo),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            ...temas.map((tema) {
              final esRelevante =
                  tema.segmentosRelevantes.contains(segmentInfo.segmento);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TopicCard(
                  tema: tema,
                  destacado: esRelevante,
                  scale: scale,
                  highContrast: hc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContenidoTemaScreen(
                          tema: tema,
                          segmentInfo: segmentInfo,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final double scale;
  final bool highContrast;
  final VoidCallback onTap;

  const _RouteCard({
    required this.scale,
    required this.highContrast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highContrast ? Colors.black : AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cómo empezar a jubilarme',
                    style: AppTextStyles.heading(scale * 0.8,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La ruta paso a paso, en 5 pasos simples.',
                    style: AppTextStyles.small(scale, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic tema;
  final bool destacado;
  final double scale;
  final bool highContrast;
  final VoidCallback onTap;

  const _TopicCard({
    required this.tema,
    required this.destacado,
    required this.scale,
    required this.highContrast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highContrast ? Colors.black : AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destacado ? accent : AppColors.creamDeep,
            width: destacado ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tema.icono, color: accent, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (destacado) ...[
                    AppChip(label: 'Relevante para tu etapa', color: accent),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    tema.titulo,
                    style: AppTextStyles.heading(scale * 0.78,
                        color: highContrast ? Colors.black : null),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tema.resumen,
                    style: AppTextStyles.small(scale,
                        color: highContrast ? Colors.black54 : null),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: highContrast ? Colors.black : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
