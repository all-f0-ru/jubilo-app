import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/models/topic.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

/// 9️⃣ "Contenido de tema": desarrollo completo de un tema, con una nota
/// extra si aplica al segmento de la persona, chips de glosario tocables
/// (abren una hoja inferior con la definición) y un botón "Escuchar".
///
/// Nota: el botón "Escuchar" todavía no está conectado a una librería de
/// texto a voz real (requeriría agregar el paquete flutter_tts al
/// proyecto). Por ahora muestra un aviso, para no prometer algo que
/// todavía no funciona.
class ContenidoTemaScreen extends StatelessWidget {
  final Topic tema;
  final UserSegmentInfo segmentInfo;

  const ContenidoTemaScreen({
    super.key,
    required this.tema,
    required this.segmentInfo,
  });

  void _mostrarGlosario(BuildContext context, GlossaryTerm termino, bool hc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hc ? Colors.white : AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(termino.termino,
                  style: AppTextStyles.heading(1.0,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 10),
              Text(termino.definicion,
                  style: AppTextStyles.body(1.0,
                      color: hc ? Colors.black87 : null)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final notaSegmento = tema.notaPorSegmento[segmentInfo.segmento];

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(tema.titulo,
            style: AppTextStyles.heading(0.75, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Row(
              children: [
                IconBadge(
                  icon: tema.icono,
                  color: hc ? Colors.black : AppColors.teal,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tema.resumen,
                    style: AppTextStyles.body(scale * 0.9,
                        color: hc ? Colors.black87 : AppColors.inkSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Lectura en voz alta: función en desarrollo'),
                  ),
                );
              },
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Escuchar'),
            ),
            const SizedBox(height: 24),

            JubiloCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < tema.contenido.length; i++) ...[
                    Text(
                      tema.contenido[i],
                      style: AppTextStyles.body(scale,
                          color: hc ? Colors.black87 : null),
                    ),
                    if (i != tema.contenido.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (notaSegmento != null) ...[
              InfoBanner(
                variant: BannerVariant.info,
                fontScale: scale,
                text: notaSegmento,
              ),
              const SizedBox(height: 20),
            ],

            if (tema.glosario.isNotEmpty) ...[
              Text('Palabras clave',
                  style: AppTextStyles.heading(scale * 0.8,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tema.glosario.map((g) {
                  final c = hc ? Colors.black : AppColors.coralDeep;
                  return InkWell(
                    onTap: () => _mostrarGlosario(context, g, hc),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: c),
                          const SizedBox(width: 6),
                          Text(
                            g.termino,
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
