import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulador_models.dart';
import '../services/nube_service.dart';

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
  static const String _kExtras = 'calc_extras';

  SimuladorRespuestas? _respuestas;
  DateTime? _fecha;
  bool _cargado = false;

  // Datos que la persona escribe en las calculadoras. Se comparten entre
  // todas las modalidades para no tener que escribirlos de nuevo.
  int? _saldoClp;
  int? _edad;
  int? _aniosCotizados;

  /// Resto de los datos de la simulación: % a renta vitalicia, años de renta
  /// temporal, relación, edades de los hijos/as, sexo y edad del cónyuge.
  Map<String, dynamic> _extras = {};

  Timer? _temporizador;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  RespuestasEncuestaProvider() {
    _cargar();
    NubeService.alHabilitarGuardado(_subirTodo);
  }

  SimuladorRespuestas? get respuestas => _respuestas;
  DateTime? get fecha => _fecha;
  bool get cargado => _cargado;
  bool get tieneRespuestas => _respuestas != null;
  int? get saldoClp => _saldoClp;
  int? get edad => _edad;
  int? get aniosCotizados => _aniosCotizados;

  int? extraInt(String clave) {
    final v = _extras[clave];
    return v is num ? v.toInt() : null;
  }

  String? extraTexto(String clave) {
    final v = _extras[clave];
    return v is String ? v : null;
  }

  List<int> extraListaInt(String clave) {
    final v = _extras[clave];
    if (v is List) return [for (final e in v) if (e is num) e.toInt()];
    return const [];
  }

  /// Guarda otros datos de la simulación (ver [_extras]).
  Future<void> recordarExtras(Map<String, dynamic> datos) async {
    _extras = {..._extras, ...datos};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kExtras, jsonEncode(_extras));
    } catch (_) {}
    _programarNube();
  }

  void _programarNube() {
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 2), () {
      NubeService.guardarDatosCalculo(
          saldoClp: _saldoClp,
          edad: _edad,
          aniosCotizados: _aniosCotizados,
          extras: _extras);
    });
  }

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
    // A la nube se envía con una pequeña espera, porque estos datos cambian
    // con cada número que la persona escribe.
    _programarNube();
  }

  /// Cuando la persona opta por Premium, sube lo que ya tenía guardado.
  Future<void> _subirTodo() async {
    final r = _respuestas;
    if (r != null && _fecha != null) {
      await NubeService.guardarEncuesta(r.toJson(), _fecha!);
    }
    await NubeService.guardarDatosCalculo(
        saldoClp: _saldoClp,
        edad: _edad,
        aniosCotizados: _aniosCotizados,
        extras: _extras);
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _saldoClp = prefs.getInt(_kSaldo);
      _edad = prefs.getInt(_kEdad);
      _aniosCotizados = prefs.getInt(_kAniosCot);
      final extrasRaw = prefs.getString(_kExtras);
      if (extrasRaw != null) {
        _extras = Map<String, dynamic>.from(jsonDecode(extrasRaw) as Map);
      }
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
    await _traerDeLaNube();
  }

  /// Si en este dispositivo no hay datos pero en la nube sí (la persona
  /// vuelve a entrar), los recupera.
  Future<void> _traerDeLaNube() async {
    if (!NubeService.disponible || !NubeService.guardadoHabilitado) return;
    try {
      final datos = await NubeService.leerUsuario();
      if (datos == null) return;
      var cambio = false;
      if (_respuestas == null && datos['encuesta'] is Map) {
        final r = SimuladorRespuestas.fromJson(
            Map<String, dynamic>.from(datos['encuesta'] as Map));
        if (r != null) {
          _respuestas = r;
          _fecha = DateTime.tryParse(datos['encuestaFecha'] as String? ?? '');
          cambio = true;
        }
      }
      final calculo = datos['calculo'];
      if (calculo is Map) {
        if (_saldoClp == null && calculo['saldoClp'] is num) {
          _saldoClp = (calculo['saldoClp'] as num).toInt();
          cambio = true;
        }
        if (_edad == null && calculo['edad'] is num) {
          _edad = (calculo['edad'] as num).toInt();
          cambio = true;
        }
        if (_aniosCotizados == null && calculo['aniosCotizados'] is num) {
          _aniosCotizados = (calculo['aniosCotizados'] as num).toInt();
          cambio = true;
        }
        if (_extras.isEmpty && calculo['extras'] is Map) {
          _extras = Map<String, dynamic>.from(calculo['extras'] as Map);
          cambio = true;
        }
      }
      if (cambio) notifyListeners();
    } catch (_) {}
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
    await NubeService.guardarEncuesta(respuestas.toJson(), _fecha!);
  }

  Future<void> borrar() async {
    _respuestas = null;
    _fecha = null;
    _saldoClp = null;
    _edad = null;
    _aniosCotizados = null;
    _extras = {};
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
      await prefs.remove(_kSaldo);
      await prefs.remove(_kEdad);
      await prefs.remove(_kAniosCot);
      await prefs.remove(_kExtras);
    } catch (_) {}
  }
}
