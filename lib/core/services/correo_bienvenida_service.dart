import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_clientes_service.dart';

/// Envía el correo de bienvenida cuando la persona se une a Premium.
///
/// Usa EmailJS (https://www.emailjs.com), un servicio que manda el correo
/// por nosotros y funciona sin servidor propio ni plan de pago de Firebase.
/// Mientras los tres datos de abajo digan "PENDIENTE", no se envía nada y la
/// app funciona igual.
class CorreoBienvenidaService {
  CorreoBienvenidaService._();

  // --- Se completan con los datos de tu cuenta de EmailJS ---
  static const String serviceId = 'PENDIENTE'; // ej. service_ab12cd3
  static const String templateId = 'PENDIENTE'; // ej. template_xy98zw7
  static const String publicKey = 'PENDIENTE'; // ej. aBcDeFgHiJkLmNoPq

  static const String _claveEnviado = 'correo_bienvenida_enviado';

  static bool get configurado =>
      serviceId != 'PENDIENTE' &&
      templateId != 'PENDIENTE' &&
      publicKey != 'PENDIENTE';

  /// Manda el correo una sola vez por dispositivo. Nunca lanza errores: si
  /// falla, Premium se activa igual.
  static Future<void> enviarSiCorresponde() async {
    if (!configurado) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_claveEnviado) ?? false) return;

      final cliente = await RegistroClientesService.leer();
      if (cliente == null || cliente.correo.trim().isEmpty) return;

      final respuesta = await http
          .post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              'template_params': {
                'nombre': cliente.nombre.trim().split(' ').first,
                'nombre_completo': cliente.nombre.trim(),
                'correo': cliente.correo.trim(),
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        await prefs.setBool(_claveEnviado, true);
      } else {
        debugPrint('No se pudo enviar el correo: ${respuesta.body}');
      }
    } catch (e) {
      debugPrint('No se pudo enviar el correo de bienvenida: $e');
    }
  }

  /// Si Premium se desactiva (pruebas), permite enviar de nuevo.
  static Future<void> reiniciar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claveEnviado);
    } catch (_) {}
  }
}
