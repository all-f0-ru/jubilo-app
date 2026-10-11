import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

/// "Personalicemos tu guía": pregunta sexo y edad una sola vez. La
/// respuesta se guarda en [SettingsProvider] (persiste entre pestañas y
/// entre sesiones), así que esta pantalla solo se vuelve a mostrar si la
/// persona la abre explícitamente para cambiar sus datos.
class CuentanosSobreTiScreen extends StatefulWidget {
  const CuentanosSobreTiScreen({super.key});

  @override
  State<CuentanosSobreTiScreen> createState() =>
      _CuentanosSobreTiScreenState();
}

class _CuentanosSobreTiScreenState extends State<CuentanosSobreTiScreen> {
  String? _sexo;
  final TextEditingController _edadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _sexo = settings.sexo;
    if (settings.edad != null) {
      _edadController.text = '${settings.edad}';
    }
  }

  @override
  void dispose() {
    _edadController.dispose();
    super.dispose();
  }

  bool get _puedeContinuar {
    final edad = int.tryParse(_edadController.text);
    return _sexo != null && edad != null && edad > 0 && edad < 120;
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
        title: Text('Aprender',
            style: AppTextStyles.heading(0.85, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Personalicemos tu guía',
                  style: AppTextStyles.heading(scale, color: hc ? Colors.black : null)),
              const SizedBox(height: 8),
              Text(
                'Con tu sexo y edad te mostramos contenido relevante '
                'para tu etapa.',
                style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
              ),
              const SizedBox(height: 28),

              Text('¿Cuál es tu sexo?',
                  style: AppTextStyles.heading(scale * 0.8,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 12),
              Row(
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
              const SizedBox(height: 28),

              Text('¿Qué edad tienes?',
                  style: AppTextStyles.heading(scale * 0.8,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 12),
              TextField(
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
                        color: hc ? Colors.black : AppColors.creamDeep,
                        width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Ver mi situación',
                onPressed: _puedeContinuar
                    ? () {
                        final edad = int.parse(_edadController.text);
                        context
                            .read<SettingsProvider>()
                            .setPersonalizacion(sexo: _sexo!, edad: edad);
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
