import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enlaces legales de la app. La política de privacidad vive en la versión
/// web (archivo web/privacidad.html) y es la misma URL que se declara en
/// Google Play Console.
class EnlacesLegales {
  EnlacesLegales._();

  static const String politicaPrivacidad =
      'https://jubilo.netlify.app/privacidad.html';

  static Future<void> abrirPoliticaPrivacidad(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(politicaPrivacidad),
          mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    mensajes.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir la política de privacidad.')));
  }
}
