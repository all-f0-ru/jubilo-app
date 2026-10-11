import 'package:flutter/material.dart';

/// Pestaña activa de la barra de navegación inferior (0=Inicio,
/// 1=Aprender, 2=Modalidades, 3=Simular). Se expone como provider para
/// que botones dentro de una pestaña (ej. "Aprender sobre mi pensión" en
/// Inicio) puedan cambiar de pestaña en vez de apilar otra pantalla
/// encima.
class MainTabProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setTab(int i) {
    if (_index != i) {
      _index = i;
      notifyListeners();
    }
  }
}
