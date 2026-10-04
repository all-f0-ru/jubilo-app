import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'simulador_detalle_screen.dart';

/// 1️⃣3️⃣ Resultados del simulador: muestra las 4 modalidades como
/// tarjetas explicativas (no hay montos, porque esto es educativo, no
/// un cálculo real todavía) y permite entrar al detalle de cada una.
class SimuladorResultadosScreen extends StatelessWidget {
  final SimuladorRespuestas respuestas;

  const SimuladorResultadosScreen({super.key, required this.respuestas});

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
        title: Text('Tus modalidades',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Según tus respuestas (${respuestas.edad} años, '
              '${respuestas.sexo.toLowerCase()}, '
              '${respuestas.estadoCivil.toLowerCase()}'
              '${respuestas.tieneHijos ? ", con hijos/as" : ""}), estas '
              'son las 4 modalidades que existen en Chile.',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 16),
            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Esto es una simulación orientativa y educativa. No '
                  'reemplaza el cálculo oficial de tu AFP ni una '
                  'compañía de seguros.',
            ),
            const SizedBox(height: 20),
            ...modalidadesPension.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ModalidadCard(
                  modalidad: m,
                  scale: scale,
                  hc: hc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SimuladorDetalleScreen(modalidad: m),
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

class _ModalidadCard extends StatelessWidget {
  final ModalidadInfo modalidad;
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _ModalidadCard({
    required this.modalidad,
    required this.scale,
    required this.hc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.creamDeep),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_balance_outlined, color: accent, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modalidad.nombre,
                    style: AppTextStyles.heading(scale * 0.78,
                        color: hc ? Colors.black : null),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modalidad.resumen,
                    style: AppTextStyles.small(scale,
                        color: hc ? Colors.black54 : null),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: hc ? Colors.black : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
