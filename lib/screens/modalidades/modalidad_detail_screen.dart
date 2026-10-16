import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/boton_escuchar.dart';
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

            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: BotonEscuchar(
                highContrast: hc,
                texto: '${modalidad.nombre}. ${modalidad.resumen} '
                    'Es ideal: ${modalidad.idealPara}',
              ),
            ),
            const SizedBox(height: 18),

            // El detalle queda plegado: se abre solo si la persona quiere.
            Plegable(
              titulo: '¿Para quién es ideal?',
              icono: Icons.person_search_outlined,
              color: color,
              abiertoInicial: true,
              highContrast: hc,
              fontScale: scale,
              child: Text(modalidad.idealPara,
                  style: AppTextStyles.body(scale,
                      color: hc ? Colors.black87 : null)),
            ),
            const SizedBox(height: 12),
            Plegable(
              titulo: 'Ventajas',
              icono: Icons.check_circle_outline_rounded,
              color: hc ? Colors.black : AppColors.success,
              detalle: '${modalidad.ventajas.length}',
              highContrast: hc,
              fontScale: scale,
              child: _ListaConEstilo(
                icono: Icons.check_circle_rounded,
                color: hc ? Colors.black : AppColors.success,
                items: modalidad.ventajas,
                scale: scale,
                hc: hc,
              ),
            ),
            const SizedBox(height: 12),
            Plegable(
              titulo: 'Desventajas',
              icono: Icons.highlight_off_rounded,
              color: hc ? Colors.black : AppColors.error,
              detalle: '${modalidad.desventajas.length}',
              highContrast: hc,
              fontScale: scale,
              child: _ListaConEstilo(
                icono: Icons.cancel_rounded,
                color: hc ? Colors.black : AppColors.error,
                items: modalidad.desventajas,
                scale: scale,
                hc: hc,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Descripción educativa. El monto real lo calcula tu AFP o una '
              'aseguradora.',
              style: AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de ventajas o desventajas, una por línea y con su ícono.
class _ListaConEstilo extends StatelessWidget {
  final IconData icono;
  final Color color;
  final List<String> items;
  final double scale;
  final bool hc;

  const _ListaConEstilo({
    required this.icono,
    required this.color,
    required this.items,
    required this.scale,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final texto in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(icono, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(texto,
                      style: AppTextStyles.body(scale,
                          color: hc ? Colors.black87 : AppColors.ink)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
