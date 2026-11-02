import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulacion_guardada.dart';

/// Simulaciones guardadas por la persona (función Premium).
///
/// Por ahora se guardan en el dispositivo (SharedPreferences). Para que
/// sigan disponibles al cambiar de teléfono hay que llevarlas a una base de
/// datos en la nube (Firestore) asociada a la cuenta; el resto de la app no
/// cambia, solo este archivo.
class SimulacionesProvider extends ChangeNotifier {
  static const String _clave = 'simulaciones_guardadas';

  final List<SimulacionGuardada> _items = [];
  bool _cargado = false;

  SimulacionesProvider() {
    _cargar();
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
  }

  Future<void> eliminar(String id) async {
    _items.removeWhere((s) => s.id == id);
    notifyListeners();
    await _persistir();
  }
}
