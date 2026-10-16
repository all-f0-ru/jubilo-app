import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/boton_escuchar.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';

class _Paso {
  final String titulo;
  final String descripcion;
  const _Paso(this.titulo, this.descripcion);
}

const List<_Paso> _pasos = [
  _Paso(
    'Revisa tu ahorro',
    'Entra al sitio o app de tu AFP con tu clave única y pide tu '
        'Certificado de Saldo, para saber cuánto llevas ahorrado.',
  ),
  _Paso(
    'Compara tus opciones',
    'Pide a tu AFP ofertas de pensión en las distintas modalidades, para '
        'comparar cuánto recibirías en cada una.',
  ),
  _Paso(
    'Revisa beneficios adicionales',
    'Pregunta por la PGU, el Bono por Hijo y otros beneficios del Estado '
        'que podrían sumarse a tu pensión.',
  ),
  _Paso(
    'Elige tu modalidad',
    'Con la información comparada, elige la modalidad de pensión que '
        'mejor se ajuste a tu situación.',
  ),
  _Paso(
    'Solicita tu pensión',
    'Firma la solicitud con tu AFP (o la compañía de seguros, según la '
        'modalidad elegida) y comienza a recibir tu pensión.',
  ),
];

/// 🔟 "Cómo empezar a jubilarme": la ruta de 5 pasos para iniciar el
/// trámite de pensión. Cada paso se abre con un toque para ver el detalle y
/// se puede marcar como hecho; el avance queda guardado en el dispositivo.
class ComoEmpezarScreen extends StatefulWidget {
  final UserSegmentInfo segmentInfo;

  const ComoEmpezarScreen({super.key, required this.segmentInfo});

  @override
  State<ComoEmpezarScreen> createState() => _ComoEmpezarScreenState();
}

class _ComoEmpezarScreenState extends State<ComoEmpezarScreen> {
  static const String _kHechos = 'ruta_pasos_hechos';

  final Set<int> _hechos = <int>{};
  int? _abierto = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(_kHechos) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _hechos
        ..clear()
        ..addAll(guardados.map((s) => int.tryParse(s)).whereType<int>());
    });
  }

  Future<void> _alternarHecho(int i) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_hechos.remove(i)) _hechos.add(i);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHechos, _hechos.map((e) => '$e').toList());
  }

  void _alternarAbierto(int i) {
    HapticFeedback.selectionClick();
    setState(() => _abierto = _abierto == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;
    final hecho = hc ? Colors.black : AppColors.success;
    final duracion = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final progreso = _hechos.length / _pasos.length;

    final partesVoz = <String>['Tu ruta para jubilarte tiene cinco pasos.'];
    for (final p in _pasos) {
      partesVoz.add('${p.titulo}. ${p.descripcion}');
    }
    final textoVoz = partesVoz.join(' ');

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cómo empezar a jubilarme',
            style: AppTextStyles.heading(0.78, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // Avance de la ruta.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('${_hechos.length} de ${_pasos.length} pasos',
                      style: AppTextStyles.body(scale,
                              color: hc ? Colors.black : AppColors.tealDeep)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                BotonEscuchar(highContrast: hc, texto: textoVoz),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progreso),
                duration: duracion,
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => LinearProgressIndicator(
                  value: valor,
                  minHeight: 10,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(hecho),
                ),
              ),
            ),
            const SizedBox(height: 24),

            for (int i = 0; i < _pasos.length; i++)
              FadeSlideIn(
                index: i,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          // Tocar el círculo marca el paso como hecho.
                          Semantics(
                            button: true,
                            label: _hechos.contains(i)
                                ? 'Paso ${i + 1} hecho. Tocar para desmarcar'
                                : 'Marcar el paso ${i + 1} como hecho',
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _alternarHecho(i),
                              child: AnimatedContainer(
                                duration: duracion,
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _hechos.contains(i) ? hecho : accent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: _hechos.contains(i)
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 26)
                                    : Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (i != _pasos.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: accent.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _alternarAbierto(i),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _pasos[i].titulo,
                                          style: AppTextStyles.heading(
                                              scale * 0.8,
                                              color:
                                                  hc ? Colors.black : null),
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _abierto == i ? 0.5 : 0,
                                      duration: duracion,
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 28,
                                        color: hc
                                            ? Colors.black
                                            : AppColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: duracion,
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topCenter,
                                  child: _abierto == i
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            _pasos[i].descripcion,
                                            style: AppTextStyles.body(scale,
                                                color: hc
                                                    ? Colors.black87
                                                    : null),
                                          ),
                                        )
                                      : const SizedBox(width: double.infinity),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),
            InfoBanner(
              variant: BannerVariant.info,
              fontScale: scale,
              text: 'Puedes pedir ayuda a un familiar en cualquier paso.',
            ),
          ],
        ),
      ),
    );
  }
}
