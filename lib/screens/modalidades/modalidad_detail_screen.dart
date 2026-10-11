import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/jubilo_app_bar.dart';

/// Detalle de una modalidad de pensión: tarjeta de color con el ícono y
/// nombre, "¿Para quién es ideal?", Ventajas (verde) y Desventajas
/// (rojo) — mismo patrón visual para las 4 modalidades.
class ModalidadDetailScreen extends StatelessWidget {
  final ModalidadInfo modalidad;

  const ModalidadDetailScreen({super.key, required this.modalidad});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final color = hc ? Colors.black : modalidad.color;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: jubiloAppBar(context,
          title: modalidad.nombre, highContrast: hc, titleScale: 0.72),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // Tarjeta de color con ícono + nombre + resumen.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(modalidad.icono, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(modalidad.nombre,
                      style: AppTextStyles.heading(scale, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(modalidad.resumen,
                      style: AppTextStyles.body(scale, color: Colors.white.withValues(alpha: 0.92))),
                ],
              ),
            ),
            const SizedBox(height: 18),

            JubiloCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Para quién es ideal?',
                      style: AppTextStyles.heading(scale * 0.78,
                          color: hc ? Colors.black : AppColors.tealDeep)),
                  const SizedBox(height: 8),
                  Text(modalidad.idealPara,
                      style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _ListaConEstilo(
              titulo: 'Ventajas',
              icono: Icons.check_circle_rounded,
              color: hc ? Colors.black : AppColors.success,
              bg: hc ? Colors.black.withValues(alpha: 0.05) : const Color(0xFFE6F3EA),
              items: modalidad.ventajas,
              scale: scale,
              hc: hc,
            ),
            const SizedBox(height: 20),
            _ListaConEstilo(
              titulo: 'Desventajas',
              icono: Icons.cancel_rounded,
              color: hc ? Colors.black : AppColors.error,
              bg: hc ? Colors.black.withValues(alpha: 0.05) : const Color(0xFFFBE9E9),
              items: modalidad.desventajas,
              scale: scale,
              hc: hc,
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

class _ListaConEstilo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final Color bg;
  final List<String> items;
  final double scale;
  final bool hc;

  const _ListaConEstilo({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.bg,
    required this.items,
    required this.scale,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: color),
            const SizedBox(width: 8),
            Text(titulo,
                style: AppTextStyles.heading(scale * 0.78, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((texto) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(texto,
                      style: AppTextStyles.body(scale,
                          color: hc ? Colors.black87 : AppColors.ink)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
