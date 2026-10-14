/// Carga de las tablas de mortalidad TM2020 desde texto CSV.
///
/// Es Dart puro (sin Flutter) para poder probarlo con `flutter test`
/// leyendo los archivos del disco. La versión que lee desde los assets de
/// la app está en tm2020_assets.dart.
///
/// Formato de cada CSV (el mismo que espera `cargar_tabla_csv` en Python):
///
///   edad,qx,2021,2022,...,2036
///
/// - edad: 0..110
/// - qx: tasa de mortalidad base TM2020 (año 2020)
/// - 2021..2036: factores de mejoramiento AA(x,t)
///
/// ORIGEN DE LOS DATOS: archivos "tablas_mortalidad/*2020*.xlsx" que
/// acompañan las "Bases de datos utilizadas para la construcción de las
/// Tablas de Mortalidad 2020" (CMF / Superintendencia de Pensiones).
///
/// NOTA SOBRE RV-M-2020: la tabla oficial de mujeres causantes parte en la
/// edad 20, y el motor exige edades 0..110. Las edades 0..19 de ese CSV
/// fueron rellenadas (qx de la edad 20 y factores AA en 0). No influyen en
/// ningún afiliado de 55 años o más.
library;

import 'dart:convert';

import 'cnu_engine.dart';

/// Nombres de las 5 tablas oficiales, que coinciden con los nombres de
/// archivo (`NOMBRE.csv`).
const List<String> nombresTablasTm2020 = [
  'CB-H-2020',
  'MI-H-2020',
  'RV-M-2020',
  'B-M-2020',
  'MI-M-2020',
];

/// Convierte el texto de un CSV en una [MortalityTable].
MortalityTable parseTablaCsv(String contenido, String name) {
  // Quita el BOM si el archivo viene de Excel.
  final texto = contenido.startsWith('﻿') ? contenido.substring(1) : contenido;

  final lineas = const LineSplitter()
      .convert(texto)
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (lineas.isEmpty) {
    throw CNUException('CSV sin encabezado: $name');
  }

  final encabezado = lineas.first.split(',').map((c) => c.trim()).toList();

  final idxEdad = encabezado.indexOf('edad');
  final idxQx = encabezado.indexOf('qx');
  if (idxEdad < 0) throw CNUException("$name: falta columna 'edad'.");
  if (idxQx < 0) throw CNUException("$name: falta columna 'qx'.");

  // Columnas de años >= 2021, ordenadas.
  final columnasAnio = <int, int>{}; // año -> índice de columna
  for (var i = 0; i < encabezado.length; i++) {
    final anio = int.tryParse(encabezado[i]);
    if (anio != null && anio >= tm2020FirstImprovementYear) {
      columnasAnio[anio] = i;
    }
  }

  final qx = <int, double>{};
  final improvement = <int, Map<int, double>>{};

  for (var n = 1; n < lineas.length; n++) {
    final celdas = lineas[n].split(',').map((c) => c.trim()).toList();
    if (celdas.length < encabezado.length) {
      throw CNUException('$name: fila ${n + 1} incompleta.');
    }

    final edad = int.parse(celdas[idxEdad]);
    qx[edad] = double.parse(celdas[idxQx]);

    final fila = <int, double>{};
    columnasAnio.forEach((anio, idx) {
      final valor = celdas[idx];
      if (valor.isNotEmpty) {
        fila[anio] = double.parse(valor);
      }
    });
    improvement[edad] = fila;
  }

  return MortalityTable(name: name, qx: qx, improvement: improvement);
}

/// Construye el mapa nombre -> tabla a partir de los textos de los CSV.
///
/// [csvPorNombre] debe contener las 5 tablas oficiales.
Map<String, MortalityTable> tablasDesdeTextos(Map<String, String> csvPorNombre) {
  final tablas = <String, MortalityTable>{};
  for (final nombre in nombresTablasTm2020) {
    final contenido = csvPorNombre[nombre];
    if (contenido == null) {
      throw CNUException('Falta el CSV de la tabla $nombre.');
    }
    tablas[nombre] = parseTablaCsv(contenido, nombre);
  }
  return tablas;
}
