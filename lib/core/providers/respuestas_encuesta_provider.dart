import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulador_models.dart';

/// Recuerda las respuestas de la encuesta del simulador (edad, sexo, estado
/// civil e hijos) para que la persona no tenga que contestarla de nuevo.
///
/// HOY: se guardan solo en este dispositivo.
/// PRÓXIMO PASO (Firebase): además de guardar local, enviar las respuestas
/// al documento de la persona en Firestore (`usuarios/{uid}`) y leerlas al
/// iniciar sesión, para recuperarlas en otro dispositivo.
class RespuestasEncuestaProvider extends ChangeNotifier {
  static const String _clave = 'simulador_respuestas';

  static const String _kSaldo = 'calc_saldo';
  static const String _kEdad = 'calc_edad';
  static const String _kAniosCot = 'calc_anios_cotizados';

  SimuladorRespuestas? _respuestas;
  DateTime? _fecha;
  bool _cargado = false;

  // Datos que la persona escribe en las calculadoras. Se comparten entre
  // todas las modalidades para no tener que escribirlos de nuevo.
  int? _saldoClp;
  int? _edad;
  int? _aniosCotizados;

  RespuestasEncuestaProvider() {
    _cargar();
  }

  SimuladorRespuestas? get respuestas => _respuestas;
  DateTime? get fecha => _fecha;
  bool get cargado => _cargado;
  bool get tieneRespuestas => _respuestas != null;
  int? get saldoClp => _saldoClp;
  int? get edad => _edad;
  int? get aniosCotizados => _aniosCotizados;

  /// Recuerda los datos de las calculadoras. No avisa a las pantallas (no
  /// hace falta redibujar nada) y solo guarda lo que viene con valor.
  Future<void> recordarDatos(
      {int? saldoClp, int? edad, int? aniosCotizados}) async {
    if (saldoClp != null && saldoClp > 0) _saldoClp = saldoClp;
    if (edad != null) _edad = edad;
    if (aniosCotizados != null) _aniosCotizados = aniosCotizados;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_saldoClp != null) await prefs.setInt(_kSaldo, _saldoClp!);
      if (_edad != null) await prefs.setInt(_kEdad, _edad!);
      if (_aniosCotizados != null) {
        await prefs.setInt(_kAniosCot, _aniosCotizados!);
      }
    } catch (_) {}
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _saldoClp = prefs.getInt(_kSaldo);
      _edad = prefs.getInt(_kEdad);
      _aniosCotizados = prefs.getInt(_kAniosCot);
      final raw = prefs.getString(_clave);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _respuestas =
            SimuladorRespuestas.fromJson(j['respuestas'] as Map<String, dynamic>);
        _fecha = DateTime.tryParse(j['fecha'] as String? ?? '');
      }
    } catch (_) {
      _respuestas = null;
    }
    _cargado = true;
    notifyListeners();
  }

  Future<void> guardar(SimuladorRespuestas respuestas) async {
    _respuestas = respuestas;
    _fecha = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode({
          'respuestas': respuestas.toJson(),
          'fecha': _fecha!.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> borrar() async {
    _respuestas = null;
    _fecha = null;
    _saldoClp = null;
    _edad = null;
    _aniosCotizados = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
      await prefs.remove(_kSaldo);
      await prefs.remove(_kEdad);
      await prefs.remove(_kAniosCot);
    } catch (_) {}
  }
}
