import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/voz_service.dart';
import '../theme/app_colors.dart';

/// Botón "Escuchar / Detener" que lee [texto] en voz alta.
/// No se muestra si la persona desactivó la voz en Configuración.
class BotonEscuchar extends StatefulWidget {
  final String texto;
  final bool highContrast;

  const BotonEscuchar({
    super.key,
    required this.texto,
    this.highContrast = false,
  });

  @override
  State<BotonEscuchar> createState() => _BotonEscucharState();
}

class _BotonEscucharState extends State<BotonEscuchar> {
  @override
  void dispose() {
    // Al salir de la pantalla se corta la lectura.
    VozService.instancia.detener();
    super.dispose();
  }

  Future<void> _alternar(bool hablando) async {
    HapticFeedback.selectionClick();
    if (hablando) {
      await VozService.instancia.detener();
      return;
    }
    final ok = await VozService.instancia.hablar(widget.texto);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos reproducir la voz en este dispositivo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vozActiva = context.watch<SettingsProvider>().voiceEnabled;
    if (!vozActiva) return const SizedBox.shrink();

    final color = widget.highContrast ? Colors.black : AppColors.tealDeep;

    return ValueListenableBuilder<bool>(
      valueListenable: VozService.instancia.hablando,
      builder: (context, hablando, _) {
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _alternar(hablando),
          icon: Icon(
            hablando ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          ),
          label: Text(hablando ? 'Detener' : 'Escuchar'),
        );
      },
    );
  }
}
