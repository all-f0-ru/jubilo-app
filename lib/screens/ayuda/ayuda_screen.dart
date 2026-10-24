import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

class _FuenteOficial {
  final String nombre;
  final String descripcion;
  final String direccion;
  final IconData icono;

  const _FuenteOficial({
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.icono,
  });
}

const List<_FuenteOficial> _fuentes = [
  _FuenteOficial(
    nombre: 'Superintendencia de Pensiones',
    descripcion: 'Regula el sistema de pensiones. Información oficial sobre '
        'modalidades, saldos y reclamos.',
    direccion: 'www.spensiones.cl',
    icono: Icons.account_balance_outlined,
  ),
  _FuenteOficial(
    nombre: 'Instituto de Previsión Social (IPS)',
    descripcion: 'Información y trámites de beneficios del Estado, como la '
        'Pensión Garantizada Universal.',
    direccion: 'www.ips.gob.cl',
    icono: Icons.volunteer_activism_outlined,
  ),
  _FuenteOficial(
    nombre: 'ChileAtiende',
    descripcion: 'Guías y trámites del Estado, explicados paso a paso.',
    direccion: 'www.chileatiende.gob.cl',
    icono: Icons.support_agent_outlined,
  ),
];

/// Pantalla de Ayuda, accesible desde el ícono (?) en cualquier pestaña.
/// Reúne solo fuentes oficiales (Superintendencia de Pensiones, IPS,
/// ChileAtiende). Al tocar una fuente se abre su sitio (url_launcher); si
/// no se puede abrir, se copia la dirección.
class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

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
        title: Text('Ayuda',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('¿Necesitas más información?',
                style: AppTextStyles.heading(scale, color: hc ? Colors.black : null)),
            const SizedBox(height: 8),
            Text(
              'Estas son las instituciones oficiales donde puedes consultar '
              'y hacer tus trámites.',
              style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
            const SizedBox(height: 24),

            ..._fuentes.map((f) {
              final color = hc ? Colors.black : AppColors.teal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: JubiloCard(
                  onTap: () => _abrirDireccion(context, f.direccion),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: f.icono, color: color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.nombre,
                                style: AppTextStyles.heading(scale * 0.75,
                                    color: hc ? Colors.black : null)),
                            const SizedBox(height: 4),
                            Text(f.descripcion,
                                style: AppTextStyles.small(scale,
                                    color: hc ? Colors.black54 : null)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 16, color: color),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    f.direccion,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 6),
            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Jubilo es una guía educativa. Para trámites oficiales, '
                  'contacta a tu AFP o a las instituciones de esta lista. '
                  'Toca una para abrirla.',
            ),
          ],
        ),
      ),
    );
  }

  /// Abre solo las direcciones de la lista oficial. Si no se puede abrir,
  /// copia la dirección para que la persona la pegue en su navegador.
  Future<void> _abrirDireccion(BuildContext context, String direccion) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri.parse('https://$direccion'),
        mode: LaunchMode.externalApplication);
    if (ok) return;
    await Clipboard.setData(ClipboardData(text: direccion));
    messenger.showSnackBar(
      SnackBar(content: Text('Dirección copiada: $direccion')),
    );
  }
}
