// Pruebas del motor de pensiones portado a Dart.
//
// Los valores esperados vienen de dos fuentes:
//  1. Caso publicado por la Superintendencia de Pensiones (Nota Técnica
//     N°9): afiliada mujer 60, cónyuge hombre 65, tasa 3 %, año 2024.
//  2. Ejecución del motor Python del cliente (cnu.py V4.2 y
//     renta_vitalicia.py V5.0) con las mismas tablas TM2020.
//
// Se ejecutan con:  flutter test test/cnu_rvi_test.dart
//
// IMPORTANTE: si el nombre del paquete en pubspec.yaml (primera línea,
// "name: ...") no es jubilo_app, cambia "package:jubilo_app" por ese nombre.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jubilo_app/core/pension_engine/cnu_engine.dart';
import 'package:jubilo_app/core/pension_engine/cnu_grupo.dart';
import 'package:jubilo_app/core/pension_engine/pension_config.dart';
import 'package:jubilo_app/core/pension_engine/renta_vitalicia.dart';
import 'package:jubilo_app/core/pension_engine/tm2020_loader.dart';

Map<String, MortalityTable> _cargarTablas() {
  final textos = <String, String>{};
  for (final nombre in nombresTablasTm2020) {
    textos[nombre] = File('assets/tm2020/$nombre.csv').readAsStringSync();
  }
  return tablasDesdeTextos(textos);
}

void main() {
  late Map<String, MortalityTable> tablas;

  setUpAll(() {
    tablas = _cargarTablas();
  });

  test('carga las 5 tablas TM2020 completas (edades 0..110)', () {
    expect(tablas.length, 5);
    for (final t in tablas.values) {
      expect(t.qx.length, 111, reason: t.name);
      expect(t.qx[110], 1.0, reason: t.name);
    }
  });

  test('caso Nota Técnica N°9 de la Superintendencia', () {
    final res = calcularCnuTotal(
      grupo: const GrupoFamiliarCnu(
        afiliadoSexo: 'F',
        afiliadoEdad: 60,
        beneficiarios: [
          BeneficiarioCnu(tipo: 'conyuge', sexo: 'M', edad: 65),
        ],
      ),
      tablas: tablas,
      calculationYear: 2024,
      interestRate: 0.03,
    );

    expect(res.cnuAfiliado, closeTo(19.702604, 1e-5));
    expect(res.cnuConyuge, closeTo(0.633946, 1e-5));
    expect(res.cnuTotal, closeTo(20.336550, 1e-5));
    expect(res.tablaAfiliado, 'RV-M-2020');
    expect(res.tablaConyuge, 'CB-H-2020');
  });

  group('Renta Vitalicia Inmediata (valores del motor Python)', () {
    final fecha = DateTime(2026, 10, 13);
    final parametros = ParametrosRvi(
      fechaReferencia: fecha,
      tasaReferencia: ParametrosVigentes.tasaReferencia,
    );
    const prima = 4000.0;
    const uf = ParametrosVigentes.valorUf;

    ResultadoRentaVitalicia calcular(GrupoFamiliarRvi g) =>
        calcularRentaVitalicia(
          primaUf: prima,
          grupoFamiliar: g,
          parametros: parametros,
          valorUf: uf,
          tablas: tablas,
        );

    test('mujer de 65, sin beneficiarios', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'F',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
      ));
      expect(r.cnuTotal, closeTo(18.003123, 2e-6));
      expect(r.pensionMensualUf, closeTo(18.515306112907933, 1e-5));
      expect(r.pensionMensualClp, closeTo(761944.2841481819, 1.0));
      expect(r.cumpleUmbralMinimo, isTrue);
    });

    test('mujer de 65 con cónyuge hombre de 67', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'F',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
        beneficiarios: [
          BeneficiarioRvi(
            tipo: 'conyuge',
            sexo: 'M',
            fechaNacimiento: DateTime(1959, 10, 13),
          ),
        ],
      ));
      expect(r.cnuAfiliado, closeTo(18.003123, 2e-6));
      expect(r.cnuConyuge, closeTo(0.92765, 2e-6));
      expect(r.cnuTotal, closeTo(18.930774, 2e-6));
      expect(r.pensionMensualUf, closeTo(17.6080139847073, 1e-5));
      expect(r.pensionMensualClp, closeTo(724607.2805404927, 1.0));
    });

    test('hombre de 65, sin beneficiarios', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'M',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
      ));
      expect(r.cnuTotal, closeTo(15.769327, 2e-6));
      expect(r.pensionMensualUf, closeTo(21.138082388254954, 1e-5));
      expect(r.pensionMensualClp, closeTo(869877.1143921782, 1.0));
    });

    test('hombre de 65 con cónyuge mujer de 62', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'M',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
        beneficiarios: [
          BeneficiarioRvi(
            tipo: 'conyuge',
            sexo: 'F',
            fechaNacimiento: DateTime(1964, 10, 13),
          ),
        ],
      ));
      expect(r.cnuConyuge, closeTo(2.764415, 2e-6));
      expect(r.cnuTotal, closeTo(18.533742, 2e-6));
      expect(r.pensionMensualUf, closeTo(17.985214930332653, 1e-5));
      expect(r.pensionMensualClp, closeTo(740129.9028909903, 1.0));
    });
  });

  test('rechaza estructuras aún no portadas (no las aproxima)', () {
    expect(
      () => calcularCnuTotal(
        grupo: const GrupoFamiliarCnu(
          afiliadoSexo: 'M',
          afiliadoEdad: 65,
          beneficiarios: [
            BeneficiarioCnu(tipo: 'hijo', sexo: 'F', edad: 10),
          ],
        ),
        tablas: tablas,
        calculationYear: 2026,
        interestRate: 0.0281,
      ),
      throwsA(isA<CNUException>()),
    );
  });
}
