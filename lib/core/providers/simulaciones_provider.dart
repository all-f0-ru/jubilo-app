import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulacion_guardada.dart';
import '../services/nube_service.dart';

/// Simulaciones guardadas por la persona (función Premium).
///
/// Se guardan en el dispositivo (SharedPreferences) y también en Firestore,
/// asociadas al identificador anónimo de la persona.
class SimulacionesProvider extends ChangeNotifier {
  static const String _clave = 'simulaciones_guardadas';

  final List<SimulacionGuardada> _items = [];
  bool _cargado = false;

  SimulacionesProvider() {
    _cargar();
    // Al optar por Premium se suben las simulaciones que ya estaban guardadas.
    NubeService.alHabilitarGuardado(() async {
      for (final s in List<SimulacionGuardada>.from(_items)) {
        await NubeService.guardarSimulacion(s.toJson());
      }
    });
  }

  /// De la más antigua a la más nueva.
  List<SimulacionGuardada> get todas => List.unmodifiable(_items);

  bool get cargado => _cargado;

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave);
      if (texto != null) {
        final lista = jsonDecode(texto) as List<dynamic>;
        _items
          ..clear()
          ..addAll(lista.map(
              (e) => SimulacionGuardada.fromJson(e as Map<String, dynamic>)));
        _items.sort((a, b) => a.fecha.compareTo(b.fecha));
      }
    } catch (_) {
      // Datos dañados o sin almacenamiento: se parte con la lista vacía.
    }
    _cargado = true;
    notifyListeners();
    await _sincronizarConNube();
  }

  /// Une las simulaciones del dispositivo con las de la nube: las que
  /// faltan en un lado se copian al otro.
  Future<void> _sincronizarConNube() async {
    if (!NubeService.disponible || !NubeService.guardadoHabilitado) return;
    try {
      final remotas = await NubeService.leerSimulaciones();
      final idsRemotos = <String>{};
      var cambio = false;
      for (final j in remotas) {
        try {
          final s = SimulacionGuardada.fromJson(j);
          idsRemotos.add(s.id);
          if (!_items.any((e) => e.id == s.id)) {
            _items.add(s);
            cambio = true;
          }
        } catch (_) {}
      }
      for (final s in List<SimulacionGuardada>.from(_items)) {
        if (!idsRemotos.contains(s.id)) {
          await NubeService.guardarSimulacion(s.toJson());
        }
      }
      if (cambio) {
        _items.sort((a, b) => a.fecha.compareTo(b.fecha));
        notifyListeners();
        await _persistir();
      }
    } catch (_) {}
  }

  Future<void> _persistir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _clave, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> guardar(SimulacionGuardada simulacion) async {
    _items.add(simulacion);
    _items.sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
    await _persistir();
    await NubeService.guardarSimulacion(simulacion.toJson());
  }

  Future<void> eliminar(String id) async {
    _items.removeWhere((s) => s.id == id);
    notifyListeners();
    await _persistir();
    await NubeService.borrarSimulacion(id);
  }
}
