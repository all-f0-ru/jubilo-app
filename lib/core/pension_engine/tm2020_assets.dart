/// Lectura de las tablas TM2020 desde los assets empaquetados en la app
/// (`assets/tm2020/NOMBRE.csv`). Requiere declarar la carpeta en pubspec.yaml.
library;

import 'package:flutter/services.dart' show rootBundle;

import 'cnu_engine.dart';
import 'tm2020_loader.dart';

Map<String, MortalityTable>? _cache;

/// Carga (una sola vez) las 5 tablas oficiales desde los assets.
Future<Map<String, MortalityTable>> cargarTablasTm2020DesdeAssets() async {
  final cacheadas = _cache;
  if (cacheadas != null) return cacheadas;

  final textos = <String, String>{};
  for (final nombre in nombresTablasTm2020) {
    textos[nombre] = await rootBundle.loadString('assets/tm2020/$nombre.csv');
  }

  final tablas = tablasDesdeTextos(textos);
  _cache = tablas;
  return tablas;
}
