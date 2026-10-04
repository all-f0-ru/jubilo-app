import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

/// 1️⃣4️⃣ Detalle de una modalidad de pensión: cómo funciona, ventajas y
/// consideraciones, en lenguaje simple.
class SimuladorDetalleScreen extends StatelessWidget {
  final ModalidadInfo modalidad;

  const SimuladorDetalleScreen({super.key, required this.modalidad});

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
        title: Text(modalidad.nombre,
            style: AppTextStyles.heading(0.75, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              modalidad.resumen,
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 24),

            _Seccion(
              titulo: 'Cómo funciona',
              icono: Icons.info_outline,
              items: modalidad.comoFunciona,
              scale: scale,
              hc: hc,
              colorIcono: hc ? Colors.black : AppColors.teal,
            ),
            const SizedBox(height: 20),
            _Seccion(
              titulo: 'Ventajas',
              icono: Icons.check_circle_outline,
              items: modalidad.ventajas,
              scale: scale,
              hc: hc,
              colorIcono: hc ? Colors.black : AppColors.success,
            ),
            const SizedBox(height: 20),
            _Seccion(
              titulo: 'Qué considerar',
              icono: Icons.error_outline,
              items: modalidad.consideraciones,
              scale: scale,
              hc: hc,
              colorIcono: hc ? Colors.black : AppColors.coralDeep,
            ),
            const SizedBox(height: 24),
            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Esta descripción es educativa y general. El monto '
                  'real de tu pensión en esta modalidad solo lo puede '
                  'calcular tu AFP o una compañía de seguros.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<String> items;
  final double scale;
  final bool hc;
  final Color colorIcono;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.items,
    required this.scale,
    required this.hc,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: AppTextStyles.heading(scale * 0.8,
                color: hc ? Colors.black : null)),
        const SizedBox(height: 10),
        ...items.map((texto) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 20, color: colorIcono),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texto,
                    style: AppTextStyles.body(scale,
                        color: hc ? Colors.black87 : null),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
