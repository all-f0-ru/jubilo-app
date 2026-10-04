import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_segment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';
import 'tu_situacion_screen.dart';

/// 6️⃣ "Cuéntanos sobre ti": pregunta sexo y edad en una sola pantalla,
/// para poder calcular el segmento de la persona y personalizar el
/// contenido del flujo Aprender.
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
        title: Text('Cuéntanos sobre ti',
            style: AppTextStyles.heading(1.0, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Así te mostramos solo la información que aplica a tu '
                'situación previsional.',
                style: AppTextStyles.body(scale,
                    color: hc ? Colors.black87 : null),
              ),
              const SizedBox(height: 28),

              Text('Sexo',
                  style: AppTextStyles.heading(scale,
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

              Text('Edad',
                  style: AppTextStyles.heading(scale,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 12),
              TextField(
                controller: _edadController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.body(scale,
                    color: hc ? Colors.black : null),
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
                label: 'Ver mi información',
                onPressed: _puedeContinuar
                    ? () {
                        final edad = int.parse(_edadController.text);
                        final info =
                            computeSegment(sexo: _sexo!, edad: edad);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TuSituacionScreen(
                              segmentInfo: info,
                              edad: edad,
                            ),
                          ),
                        );
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
