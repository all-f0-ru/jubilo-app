import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'simulador_resultados_screen.dart';

/// 1️⃣2️⃣ Las 4 preguntas del simulador (edad, sexo, estado civil, hijos),
/// en una sola pantalla con pasos internos — igual que el patrón de
/// "Cuéntanos sobre ti", pero con ProgressDots para mostrar avance.
class SimuladorPreguntasScreen extends StatefulWidget {
  const SimuladorPreguntasScreen({super.key});

  @override
  State<SimuladorPreguntasScreen> createState() =>
      _SimuladorPreguntasScreenState();
}

class _SimuladorPreguntasScreenState extends State<SimuladorPreguntasScreen> {
  int _paso = 0; // 0: edad, 1: sexo, 2: estado civil, 3: hijos

  final TextEditingController _edadController = TextEditingController();
  String? _sexo;
  String? _estadoCivil;
  bool? _tieneHijos;

  static const List<String> _estadosCiviles = [
    'Soltero/a',
    'Casado/a',
    'Viudo/a',
    'Divorciado/a',
  ];

  @override
  void dispose() {
    _edadController.dispose();
    super.dispose();
  }

  bool get _puedeAvanzar {
    switch (_paso) {
      case 0:
        final edad = int.tryParse(_edadController.text);
        return edad != null && edad > 0 && edad < 120;
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
      edad: int.parse(_edadController.text),
      sexo: _sexo!,
      estadoCivil: _estadoCivil!,
      tieneHijos: _tieneHijos!,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
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

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _anterior,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressDots(total: 4, activeIndex: _paso, highContrast: hc),
              const SizedBox(height: 28),
              Expanded(child: _buildPaso(scale, hc)),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _paso < 3 ? 'Siguiente' : 'Ver resultados',
                onPressed: _puedeAvanzar ? _siguiente : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaso(double scale, bool hc) {
    switch (_paso) {
      case 0:
        return _PreguntaWrapper(
          titulo: '¿Cuál es tu edad?',
          scale: scale,
          hc: hc,
          child: TextField(
            controller: _edadController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.body(scale, color: hc ? Colors.black : null),
            decoration: InputDecoration(
              hintText: 'Ej: 58',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: hc ? Colors.black : AppColors.creamDeep, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      case 1:
        return _PreguntaWrapper(
          titulo: '¿Cuál es tu sexo?',
          scale: scale,
          hc: hc,
          child: Row(
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
          ),
        );
      case 2:
        return _PreguntaWrapper(
          titulo: '¿Cuál es tu estado civil?',
          scale: scale,
          hc: hc,
          child: Column(
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
          ),
        );
      case 3:
      default:
        return _PreguntaWrapper(
          titulo: '¿Tienes hijos/as?',
          scale: scale,
          hc: hc,
          child: Row(
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
          ),
        );
    }
  }
}

class _PreguntaWrapper extends StatelessWidget {
  final String titulo;
  final double scale;
  final bool hc;
  final Widget child;

  const _PreguntaWrapper({
    required this.titulo,
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
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
