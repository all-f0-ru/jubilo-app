import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'simulador_resultados_screen.dart';

/// Las 4 preguntas del simulador (edad, sexo, estado civil, hijos), con
/// una barra de progreso "Pregunta X de 4" y botones Atrás/Siguiente.
class SimuladorPreguntasScreen extends StatefulWidget {
  const SimuladorPreguntasScreen({super.key});

  @override
  State<SimuladorPreguntasScreen> createState() =>
      _SimuladorPreguntasScreenState();
}

class _SimuladorPreguntasScreenState extends State<SimuladorPreguntasScreen> {
  int _paso = 0; // 0: edad, 1: sexo, 2: estado civil, 3: hijos

  String? _rangoEdad;
  String? _sexo;
  String? _estadoCivil;
  bool? _tieneHijos;

  static const List<String> _estadosCiviles = [
    'Soltero/a',
    'Casado/a',
    'Viudo/a',
    'Divorciado/a',
  ];

  static const List<String> _preguntas = [
    '¿Qué edad tienes?',
    '¿Cuál es tu sexo?',
    '¿Cuál es tu estado civil?',
    '¿Tienes hijos/as?',
  ];

  static const List<String> _ayudas = [
    'Esto nos ayuda a ubicarte en tu etapa.',
    '',
    '',
    '',
  ];

  bool get _puedeAvanzar {
    switch (_paso) {
      case 0:
        return _rangoEdad != null;
      case 1:
        return _sexo != null;
      case 2:
        return _estadoCivil != null;
      case 3:
        return _tieneHijos != null;
      default:
        return false;
    }
  }

  void _siguiente() {
    if (_paso < 3) {
      setState(() => _paso++);
      return;
    }
    final respuestas = SimuladorRespuestas(
      rangoEdad: _rangoEdad!,
      sexo: _sexo!,
      estadoCivil: _estadoCivil!,
      tieneHijos: _tieneHijos!,
    );
    Navigator.of(context).push(
      JubiloPageRoute(
        builder: (_) => SimuladorResultadosScreen(respuestas: respuestas),
      ),
    );
  }

  void _anterior() {
    if (_paso > 0) {
      setState(() => _paso--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;
    final progreso = (_paso + 1) / 4;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Simular',
            style: AppTextStyles.heading(0.85, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pregunta ${_paso + 1} de 4',
                      style: AppTextStyles.small(scale,
                          color: hc ? Colors.black87 : AppColors.inkSoft)),
                  Text('${(progreso * 100).round()}%',
                      style: AppTextStyles.small(scale,
                          color: hc ? Colors.black87 : AppColors.inkSoft)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progreso),
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, valor, _) => LinearProgressIndicator(
                    value: valor,
                    minHeight: 8,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: reduceMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_paso),
                      child: _PreguntaWrapper(
                        titulo: _preguntas[_paso],
                        ayuda: _ayudas[_paso],
                        scale: scale,
                        hc: hc,
                        child: _buildOpciones(scale, hc),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Atrás',
                      onPressed: _anterior,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _paso < 3 ? 'Siguiente' : 'Ver resultados',
                      icon: Icons.arrow_forward_rounded,
                      trailingIcon: true,
                      onPressed: _puedeAvanzar ? _siguiente : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpciones(double scale, bool hc) {
    switch (_paso) {
      case 0:
        return Column(
          children: rangosEdadSimulador.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OptionCard(
                label: r,
                selected: _rangoEdad == r,
                highContrast: hc,
                onTap: () => setState(() => _rangoEdad = r),
              ),
            );
          }).toList(),
        );
      case 1:
        return Row(
          children: [
            Expanded(
              child: OptionCard(
                label: 'Mujer',
                selected: _sexo == 'Mujer',
                highContrast: hc,
                onTap: () => setState(() => _sexo = 'Mujer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OptionCard(
                label: 'Hombre',
                selected: _sexo == 'Hombre',
                highContrast: hc,
                onTap: () => setState(() => _sexo = 'Hombre'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: _estadosCiviles.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OptionCard(
                label: e,
                selected: _estadoCivil == e,
                highContrast: hc,
                onTap: () => setState(() => _estadoCivil = e),
              ),
            );
          }).toList(),
        );
      case 3:
      default:
        return Row(
          children: [
            Expanded(
              child: OptionCard(
                label: 'Sí',
                selected: _tieneHijos == true,
                highContrast: hc,
                onTap: () => setState(() => _tieneHijos = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OptionCard(
                label: 'No',
                selected: _tieneHijos == false,
                highContrast: hc,
                onTap: () => setState(() => _tieneHijos = false),
              ),
            ),
          ],
        );
    }
  }
}

class _PreguntaWrapper extends StatelessWidget {
  final String titulo;
  final String ayuda;
  final double scale;
  final bool hc;
  final Widget child;

  const _PreguntaWrapper({
    required this.titulo,
    required this.ayuda,
    required this.scale,
    required this.hc,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: AppTextStyles.heading(scale, color: hc ? Colors.black : null),
        ),
        if (ayuda.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            ayuda,
            style: AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
          ),
        ],
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
