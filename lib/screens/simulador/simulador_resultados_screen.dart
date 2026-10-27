import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../modalidades/modalidad_detail_screen.dart';
import 'comparar_modalidades_screen.dart';

/// Resultados del simulador: las 4 modalidades ordenadas según una
/// sugerencia orientativa calculada a partir de las respuestas (no es
/// un cálculo real de montos — eso requiere el motor actuarial, todavía
/// en desarrollo).
class SimuladorResultadosScreen extends StatelessWidget {
  final SimuladorRespuestas respuestas;

  const SimuladorResultadosScreen({super.key, required this.respuestas});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final ordenadas = ordenarModalidadesPara(respuestas);
    final chipColor = hc ? Colors.black : AppColors.teal;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Resultados',
            style: AppTextStyles.heading(0.85, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // Tu perfil en etiquetas cortas, en vez de una frase larga.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(label: respuestas.rangoEdad, color: chipColor),
                AppChip(label: respuestas.sexo, color: chipColor),
                AppChip(label: respuestas.estadoCivil, color: chipColor),
                AppChip(
                    label: respuestas.tieneHijos ? 'Con hijos/as' : 'Sin hijos/as',
                    color: chipColor),
              ],
            ),
            const SizedBox(height: 18),

            Text(
              'Orientativo, según tus respuestas. Toca una modalidad '
              'para ver su detalle y calcular tu pensión.',
              style: AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
            ),
            const SizedBox(height: 16),
            JubiloCard(
              borderColor: chipColor,
              borderWidth: 2,
              onTap: () {
                Navigator.of(context).push(
                  JubiloPageRoute(
                    builder: (_) =>
                        CompararModalidadesScreen(respuestas: respuestas),
                  ),
                );
              },
              child: Row(
                children: [
                  IconBadge(
                      icon: Icons.compare_arrows_rounded, color: chipColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Compara con tu saldo',
                        style: AppTextStyles.heading(scale * 0.8,
                            color: hc ? Colors.black : null)),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: chipColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Tus modalidades orientativas',
                style: AppTextStyles.heading(scale * 0.85,
                    color: hc ? Colors.black : null)),
            const SizedBox(height: 12),

            for (int i = 0; i < ordenadas.length; i++)
              FadeSlideIn(
                index: i,
                child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ModalidadRankCard(
                  rank: i + 1,
                  modalidad: ordenadas[i],
                  scale: scale,
                  hc: hc,
                  onTap: () {
                    Navigator.of(context).push(
                      JubiloPageRoute(
                        builder: (_) => ModalidadDetailScreen(
                            modalidad: ordenadas[i], respuestas: respuestas),
                      ),
                    );
                  },
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _ModalidadRankCard extends StatelessWidget {
  final int rank;
  final ModalidadInfo modalidad;
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _ModalidadRankCard({
    required this.rank,
    required this.modalidad,
    required this.scale,
    required this.hc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hc ? Colors.black : modalidad.color;
    return JubiloCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                )),
          ),
          const SizedBox(width: 10),
          IconBadge(icon: modalidad.icono, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modalidad.nombre,
                    style: AppTextStyles.heading(scale * 0.74,
                        color: hc ? Colors.black : null)),
                const SizedBox(height: 4),
                Text(modalidad.idealPara,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small(scale,
                        color: hc ? Colors.black54 : null)),
                if (modalidad.id == 'renta_vitalicia_inmediata' ||
                    modalidad.id == 'retiro_programado') ...[
                  const SizedBox(height: 8),
                  AppChip(label: 'Con calculadora', color: color),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: hc ? Colors.black : AppColors.inkSoft),
        ],
      ),
    );
  }
}
