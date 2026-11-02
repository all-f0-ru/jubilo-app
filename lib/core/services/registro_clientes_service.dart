import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cliente_registro.dart';

/// Guarda los datos de la persona que compra Premium.
///
/// HOY: se guardan solo en este dispositivo (SharedPreferences).
/// PRÓXIMO PASO (Firebase): dentro de [registrar], después de guardar local,
/// enviar el mismo `cliente.toJson()` a Firestore, por ejemplo:
///   await FirebaseFirestore.instance.collection('clientes').add(cliente.toJson());
/// Hay que hacerlo ANTES de activar Premium y avisar si falla. Además,
/// la Ley 21.719 exige consentimiento y política de privacidad.
class RegistroClientesService {
  static const String _clave = 'cliente_registro';

  static Future<void> registrar(ClienteRegistro cliente) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(cliente.toJson()));
  }

  static Future<ClienteRegistro?> leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_clave);
      if (raw == null) return null;
      return ClienteRegistro.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
