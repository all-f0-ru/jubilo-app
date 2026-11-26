import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comparativa_guardada.dart';
import '../services/nube_service.dart';

/// Comparativas guardadas por la persona (Premium). Se guardan en el
/// dispositivo y, cuando optó por Premium, también en su cuenta (Firebase).
class ComparativasProvider extends ChangeNotifier {
  static const String _clave = 'comparativas_guardadas';

  final List<ComparativaGuardada> _items = [];
  bool _cargado = false;

  ComparativasProvider() {
    _cargar();
    NubeService.alHabilitarGuardado(() async {
      for (final c in List<ComparativaGuardada>.from(_items)) {
        await NubeService.guardarComparativa(c.toJson());
      }
      await _traerDeLaNube();
    });
  }

  /// De la más antigua a la más nueva.
  List<ComparativaGuardada> get todas => List.unmodifiable(_items);
  bool get cargado => _cargado;

  /// ¿Ya hay una comparativa guardada con la fecha de hoy?
  bool get hayGuardadaHoy {
    final hoy = DateTime.now();
    return _items.any((c) =>
        c.fecha.year == hoy.year &&
        c.fecha.month == hoy.month &&
        c.fecha.day == hoy.day);
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave);
      if (texto != null) {
        final lista = jsonDecode(texto) as List<dynamic>;
        _items
          ..clear()
          ..addAll(lista.map((e) => ComparativaGuardada.fromJson(
              Map<String, dynamic>.from(e as Map))));
        _items.sort((a, b) => a.fecha.compareTo(b.fecha));
      }
    } catch (_) {
      // Datos dañados o sin almacenamiento: se parte con la lista vacía.
    }
    _cargado = true;
    notifyListeners();
    await _traerDeLaNube();
  }

  /// Agrega las comparativas de la cuenta que no estén en el dispositivo.
  Future<void> _traerDeLaNube() async {
    if (!NubeService.disponible || !NubeService.guardadoHabilitado) return;
    try {
      final remotas = await NubeService.leerComparativas();
      var cambio = false;
      for (final j in remotas) {
        try {
          final c = ComparativaGuardada.fromJson(j);
          if (!_items.any((e) => e.id == c.id)) {
            _items.add(c);
            cambio = true;
          }
        } catch (_) {}
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

  Future<void> guardar(ComparativaGuardada comparativa) async {
    _items.add(comparativa);
    _items.sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
    await _persistir();
    await NubeService.guardarComparativa(comparativa.toJson());
  }

  Future<void> eliminar(String id) async {
    _items.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persistir();
    await NubeService.borrarComparativa(id);
  }
}
