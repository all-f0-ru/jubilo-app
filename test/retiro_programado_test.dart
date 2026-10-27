// Pruebas del Retiro Programado portado a Dart.
//
// Los valores esperados salen de ejecutar el motor Python del cliente
// (cnu.py V4.0 con las mismas tablas TM2020) con tasa 3,31 %, año 2026 y
// saldo de 4.000 UF, aplicando la fórmula de retiro_programado.py V5.0:
//   pensión mensual UF = saldo / (CNU + z/12) / 12
//
// NOTA: el CNU del afiliado y del cónyuge se tomó de cnu_afiliado() y
// cnu_conyuge_sin_hijos() (ecuación 10 de la Nota Técnica N°9), que
// reproducen el caso oficial de la Superintendencia. La función
// calcular_cnu_total() de cnu.py V4.0 da 0,275 UF menos en el cónyuge
// (0,60 x 11/24) y NO reproduce el caso oficial (20,06155 en vez de
// 20,336550). Está pendiente de confirmar con el cliente.
//
// Se ejecutan con:  flutter test test/retiro_programado_test.dart
//
// IMPORTANTE: si el nombre del paquete en pubspec.yaml (primera línea,
// "name: ...") no es jubilo_app, cambia "package:jubilo_app" por ese nombre.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jubilo_app/core/pension_engine/cnu_engine.dart';
import 'package:jubilo_app/core/pension_engine/pension_config.dart';
import 'package:jubilo_app/core/pension_engine/renta_vitalicia.dart';
import 'package:jubilo_app/core/pension_engine/retiro_programado.dart';
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

  final fecha = DateTime(2026, 10, 13);
  const saldoUf = 4000.0;
  const uf = ParametrosVigentes.valorUf;

  ParametrosRp parametros({int z = 0}) => ParametrosRp(
        fechaReferencia: fecha,
        tasaRp: 0.0331,
        versionTasa: 'prueba',
        pensionesDevengadasPendientes: z,
      );

  ResultadoRetiroProgramado calcular(GrupoFamiliarRvi g, {int z = 0}) =>
      calcularRetiroProgramado(
        saldoUf: saldoUf,
        grupoFamiliar: g,
        parametros: parametros(z: z),
        valorUf: uf,
        tablas: tablas,
      );

  group('Retiro Programado (valores del motor Python, tasa 3,31 %)', () {
    test('mujer de 65, sin beneficiarios', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'F',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
      ));
      expect(r.cnuTotal, closeTo(16.981689, 2e-6));
      expect(r.anualidadUf, closeTo(235.5478303719, 1e-4));
      expect(r.pensionMensualUf, closeTo(19.6289858643, 1e-5));
      expect(r.pensionMensualClp, closeTo(807774.5781, 1.0));
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
      expect(r.cnuAfiliado, closeTo(16.981689, 2e-6));
      expect(r.cnuConyuge, closeTo(0.844516, 2e-6));
      expect(r.cnuTotal, closeTo(17.826204, 2e-6));
      expect(r.pensionMensualUf, closeTo(18.6990642166, 1e-5));
      expect(r.pensionMensualClp, closeTo(769506.3215, 1.0));
    });

    test('hombre de 65, sin beneficiarios', () {
      final r = calcular(GrupoFamiliarRvi(
        afiliadoSexo: 'M',
        afiliadoFechaNacimiento: DateTime(1961, 10, 13),
      ));
      expect(r.cnuTotal, closeTo(14.967473, 2e-6));
      expect(r.pensionMensualUf, closeTo(22.2705150918, 1e-5));
      expect(r.pensionMensualClp, closeTo(916479.1322, 1.0));
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
      expect(r.cnuConyuge, closeTo(2.482611, 2e-6));
      expect(r.cnuTotal, closeTo(17.450084, 2e-6));
      expect(r.pensionMensualUf, closeTo(19.1021047998, 1e-5));
      expect(r.pensionMensualClp, closeTo(786092.3000, 1.0));
    });
  });

  group('Reglas propias del Retiro Programado', () {
    final grupo = GrupoFamiliarRvi(
      afiliadoSexo: 'F',
      afiliadoFechaNacimiento: DateTime(1961, 10, 13),
    );

    test('la pensión mensual es la anualidad dividida en 12', () {
      final r = calcular(grupo);
      expect(r.pensionMensualUf * 12, closeTo(r.anualidadUf, 1e-9));
      expect(r.pensionMensualClp, closeTo(r.pensionMensualUf * uf, 1e-6));
    });

    test('z suma z/12 al denominador y baja la pensión', () {
      final sinZ = calcular(grupo);
      final conZ = calcular(grupo, z: 12);
      expect(conZ.denominador, closeTo(sinZ.cnuTotal + 1.0, 1e-9));
      expect(conZ.pensionMensualUf, lessThan(sinZ.pensionMensualUf));
      expect(
        conZ.pensionMensualUf,
        closeTo(saldoUf / (sinZ.cnuTotal + 1.0) / 12.0, 1e-9),
      );
    });

    test('con tasa 3,31 % el CNU es menor y la pensión mayor que con 2,81 %', () {
      // Una tasa mayor descuenta más, así que el CNU baja y la pensión sube.
      final rp = calcular(grupo);
      final rvi = calcularRentaVitalicia(
        primaUf: saldoUf,
        grupoFamiliar: grupo,
        parametros: ParametrosRvi(
          fechaReferencia: fecha,
          tasaReferencia: ParametrosVigentes.tasaReferencia,
        ),
        valorUf: uf,
        tablas: tablas,
      );
      expect(rp.cnuTotal, lessThan(rvi.cnuTotal));
      expect(rp.pensionMensualUf, greaterThan(rvi.pensionMensualUf));
    });

    test('rechaza saldo cero o negativo', () {
      expect(() => calcular0(tablas, grupo, 0),
          throwsA(isA<RetiroProgramadoException>()));
      expect(() => calcular0(tablas, grupo, -5),
          throwsA(isA<RetiroProgramadoException>()));
    });

    test('rechaza tasa inválida y fuente de tasa vacía', () {
      expect(
        () => calcularRetiroProgramado(
          saldoUf: saldoUf,
          grupoFamiliar: grupo,
          parametros: ParametrosRp(
            fechaReferencia: fecha,
            tasaRp: -1,
            versionTasa: 'x',
          ),
          valorUf: uf,
          tablas: tablas,
        ),
        throwsA(isA<RetiroProgramadoException>()),
      );
      expect(
        () => calcularRetiroProgramado(
          saldoUf: saldoUf,
          grupoFamiliar: grupo,
          parametros: ParametrosRp(
            fechaReferencia: fecha,
            tasaRp: 0.0331,
            versionTasa: '  ',
          ),
          valorUf: uf,
          tablas: tablas,
        ),
        throwsA(isA<RetiroProgramadoException>()),
      );
    });
  });
}

ResultadoRetiroProgramado calcular0(
  Map<String, MortalityTable> tablas,
  GrupoFamiliarRvi grupo,
  double saldo,
) {
  return calcularRetiroProgramado(
    saldoUf: saldo,
    grupoFamiliar: grupo,
    parametros: ParametrosRp(
      fechaReferencia: DateTime(2026, 10, 13),
      tasaRp: 0.0331,
      versionTasa: 'prueba',
    ),
    valorUf: ParametrosVigentes.valorUf,
    tablas: tablas,
  );
}
