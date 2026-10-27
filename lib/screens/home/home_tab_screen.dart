import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/main_tab_provider.dart';
import '../../core/models/capsula.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_app_bar.dart';
import '../aprender/como_empezar_screen.dart';

/// Raíz de la pestaña "Inicio": encabezado con logo, saludo, tarjeta de
/// etapa (vacía o personalizada), cápsulas informativas en video, y los
/// accesos directos a Aprender / Simular / "¿Por dónde empiezo?".
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _bienvenida(String? sexo) {
    if (sexo == 'Mujer') return 'Bienvenida a Jubilo';
    if (sexo == 'Hombre') return 'Bienvenido a Jubilo';
    return 'Bienvenido/a a Jubilo';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;
    final segmentInfo = settings.segmentInfo;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_rounded,
                    color: hc ? Colors.black : AppColors.coral, size: 22),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'Jubilo',
                      style: AppTextStyles.heading(0.85,
                          color: hc ? Colors.black : AppColors.tealDeep),
                    ),
                    TextSpan(
                      text: '.',
                      style: AppTextStyles.heading(0.85,
                          color: hc ? Colors.black : AppColors.coral),
                    ),
                  ]),
                ),
                const Spacer(),
                ...jubiloHeaderActions(context, highContrast: hc),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 20),

            Text(_saludo(),
                style: AppTextStyles.small(scale, color: hc ? Colors.black54 : null)),
            const SizedBox(height: 4),
            Text(_bienvenida(settings.sexo),
                style: AppTextStyles.heading(scale, color: hc ? Colors.black : null)),
            const SizedBox(height: 20),

            // Tarjeta "Tu etapa" (vacía o personalizada).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TU ETAPA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    segmentInfo != null
                        ? '${settings.sexo} · ${settings.edad} años'
                        : 'Aún no personalices tu guía',
                    style: AppTextStyles.heading(scale * 0.85, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segmentInfo != null
                        ? 'Tu guía ya está personalizada.'
                        : 'Cuéntanos tu edad y sexo.',
                    style: AppTextStyles.body(scale,
                        color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  if (segmentInfo == null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: accent,
                        side: BorderSide.none,
                      ),
                      onPressed: () =>
                          context.read<MainTabProvider>().setTab(1),
                      child: const Text('Personalizar ahora'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.play_arrow_rounded,
                    color: hc ? Colors.black : AppColors.coral, size: 20),
                const SizedBox(width: 4),
                Text('Cápsulas informativas',
                    style: AppTextStyles.heading(scale * 0.8,
                        color: hc ? Colors.black : null)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: capsulasInformativas.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return _CapsulaCard(
                    capsula: capsulasInformativas[i],
                    scale: scale,
                    hc: hc,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            _AccionCard(
              icon: Icons.menu_book_outlined,
              title: 'Aprender sobre mi pensión',
              subtitle: 'Temas simples y claros',
              color: hc ? Colors.black12 : AppColors.creamDeep,
              iconColor: hc ? Colors.black : AppColors.tealDeep,
              textColor: hc ? Colors.black : AppColors.ink,
              scale: scale,
              onTap: () => context.read<MainTabProvider>().setTab(1),
            ),
            const SizedBox(height: 14),
            _AccionCard(
              icon: Icons.calculate_outlined,
              title: 'Simular mi pensión',
              subtitle: 'Calcula tu pensión en 1 minuto',
              color: hc ? Colors.black : AppColors.coral,
              iconColor: Colors.white,
              textColor: Colors.white,
              subtitleColor: Colors.white70,
              scale: scale,
              onTap: () => context.read<MainTabProvider>().setTab(3),
            ),
            const SizedBox(height: 14),

            _PorDondeEmpiezoCard(
              scale: scale,
              hc: hc,
              onTap: () {
                if (segmentInfo != null) {
                  Navigator.of(context).push(
                    JubiloPageRoute(
                      builder: (_) =>
                          ComoEmpezarScreen(segmentInfo: segmentInfo),
                    ),
                  );
                } else {
                  context.read<MainTabProvider>().setTab(1);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsulaCard extends StatelessWidget {
  final CapsulaInformativa capsula;
  final double scale;
  final bool hc;

  const _CapsulaCard({required this.capsula, required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final url = capsula.videoUrl;
          if (url == null) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Video disponible pronto')),
            );
            return;
          }
          try {
            final ok = await launchUrl(Uri.parse(url));
            if (!ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('No se pudo abrir el video')),
              );
            }
          } catch (e) {
            debugPrint('Error al abrir video: $e');
            messenger.showSnackBar(
              SnackBar(content: Text('Error al abrir el video: $e')),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Carátula del video. Si no carga (sin internet o sin
                  // permiso), se ve el fondo de color de abajo.
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: hc
                                    ? [Colors.black87, Colors.black54]
                                    : [AppColors.tealDeep, AppColors.teal],
                              ),
                            ),
                          ),
                          if (capsula.miniaturaUrl != null) ...[
                            Image.network(
                              capsula.miniaturaUrl!,
                              fit: BoxFit.cover,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.fallback,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                            Container(color: Colors.black.withValues(alpha: 0.2)),
                          ],
                          Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Icon(Icons.play_arrow_rounded,
                                  color: hc ? Colors.black : AppColors.tealDeep,
                                  size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(capsula.duracion,
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsula.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13 * scale,
                        color: hc ? Colors.black : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capsula.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: hc ? Colors.black54 : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final Color? subtitleColor;
  final double scale;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.scale,
    required this.onTap,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.heading(scale * 0.75, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.small(scale,
                          color: subtitleColor ?? AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PorDondeEmpiezoCard extends StatelessWidget {
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _PorDondeEmpiezoCard({required this.scale, required this.hc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.alt_route_outlined, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('¿Por dónde empiezo?',
                  style: AppTextStyles.body(scale,
                      color: hc ? Colors.black : AppColors.tealDeep)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
