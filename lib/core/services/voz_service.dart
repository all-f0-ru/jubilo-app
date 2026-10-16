/// Lectura en voz alta ("Escuchar") con el motor de voz del dispositivo.
///
/// Requiere el paquete flutter_tts (`flutter pub add flutter_tts`). Si el
/// dispositivo no tiene voz disponible, [hablar] devuelve false y la app
/// muestra un aviso en vez de fallar.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VozService {
  VozService._();

  static final VozService instancia = VozService._();

  final FlutterTts _tts = FlutterTts();
  bool _listo = false;

  /// true mientras se está leyendo un texto.
  final ValueNotifier<bool> hablando = ValueNotifier<bool>(false);

  Future<void> _preparar() async {
    if (_listo) return;

    _tts.setCompletionHandler(() => hablando.value = false);
    _tts.setCancelHandler(() => hablando.value = false);
    _tts.setErrorHandler((_) => hablando.value = false);

    // Busca la voz en español más cercana al español de Chile.
    for (final idioma in const ['es-CL', 'es-419', 'es-MX', 'es-US', 'es-ES']) {
      try {
        final disponible = await _tts.isLanguageAvailable(idioma);
        if (disponible == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      } catch (_) {
        // Si no se puede consultar el idioma, se sigue con el siguiente.
      }
    }

    // Un poco más lento que lo normal, para que se entienda mejor.
    await _tts.setSpeechRate(0.45);
    _listo = true;
  }

  /// Lee [texto] en voz alta. Devuelve false si no fue posible.
  Future<bool> hablar(String texto) async {
    try {
      await _preparar();
      await _tts.stop();
      hablando.value = true;
      await _tts.speak(texto);
      return true;
    } catch (_) {
      hablando.value = false;
      return false;
    }
  }

  Future<void> detener() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Nada que hacer: igual se marca como detenido.
    }
    hablando.value = false;
  }
}
