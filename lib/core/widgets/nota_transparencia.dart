import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pension_engine/pension_config.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';

/// Nota de transparencia que va al pie de los resultados: aclara que es una
/// estimación, indica con qué parámetros y fecha se calculó, y enlaza a las
/// fuentes oficiales.
class NotaTransparencia extends StatelessWidget {
  const NotaTransparencia({super.key});

  static String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _abrir(BuildContext context, String url) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    mensajes.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final color = hc ? Colors.black : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: hc ? Colors.black : Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Importante: es una estimación',
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black : null)),
          const SizedBox(height: 6),
          Text(
            'Estos valores son referenciales. No son una oferta ni '
            'reemplazan la cotización oficial de una AFP o aseguradora. '
            'Tu monto final puede ser distinto.',
            style: AppTextStyles.small(scale, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            'Cálculo con UF de ${_fecha(ParametrosVigentes.valorUfFecha)} y '
            'tasas de referencia consultadas el '
            '${_fecha(ParametrosVigentes.tasaFechaConsulta)}.',
            style: AppTextStyles.small(scale, color: color),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              TextButton(
                onPressed: () => _abrir(context, 'https://www.spensiones.cl'),
                child: const Text('Superintendencia de Pensiones'),
              ),
              TextButton(
                onPressed: () =>
                    _abrir(context, 'https://www.chileatiende.gob.cl'),
                child: const Text('ChileAtiende'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
