import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'temas_screen.dart';

/// 7️⃣ "Tu situación": resumen personalizado según el segmento calculado
/// en la pantalla anterior. Muestra la edad legal que le corresponde, en
/// qué etapa está, y el aviso de que la edad legal no obliga a jubilarse
/// cuando corresponde.
class TuSituacionScreen extends StatelessWidget {
  final UserSegmentInfo segmentInfo;
  final int edad;

  const TuSituacionScreen({
    super.key,
    required this.segmentInfo,
    required this.edad,
  });

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
        title: Text('Tu situación',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta con los datos clave
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: hc ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hc ? Colors.black : AppColors.creamDeep,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppChip(
                      label: segmentInfo.etapa,
                      color: hc ? Colors.black : AppColors.teal,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tienes $edad años. Tu edad legal de pensión es '
                      '${segmentInfo.edadLegal} años.',
                      style: AppTextStyles.heading(scale,
                          color: hc ? Colors.black : null),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      segmentInfo.mensaje,
                      style: AppTextStyles.body(scale,
                          color: hc ? Colors.black87 : null),
                    ),
                  ],
                ),
              ),

              if (segmentInfo.mostrarAvisoNoObligacion) ...[
                const SizedBox(height: 20),
                InfoBanner(
                  variant: BannerVariant.warning,
                  fontScale: scale,
                  text:
                      'Cumplir la edad legal no significa que estés '
                      'obligado/a a jubilarte. Puedes seguir trabajando '
                      'si lo prefieres.',
                ),
              ],

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Ver los temas para mi situación',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TemasScreen(segmentInfo: segmentInfo),
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
