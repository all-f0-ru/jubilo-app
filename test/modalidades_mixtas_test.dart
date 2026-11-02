import 'package:flutter_test/flutter_test.dart';
import 'package:jubilo_app/core/pension_engine/modalidades_mixtas.dart';

// Valores de referencia generados ejecutando los scripts del cliente
// (simulador_rv_inmediata_retiro_programado.py y
// simulador_renta_temporal_vitalicia.py) con los mismos datos.
const double _uf = 41226.39;

void main() {
  group('Gompertz', () {
    test('calibración y factor de anualidad calzan con Python', () {
      final a = calibrarGompertz(63);
      expect(a, closeTo(2.4299101115536414e-05, 1e-12));
      expect(factorAnualidadGompertz(a, 63, 0.03),
          closeTo(178.73130703317, 1e-6));
    });
  });

  group('RV Inmediata con Retiro Programado', () {
    ResultadoRvRp sim(double pct) => simularRvInmediataConRp(
          saldoClp: 140000000,
          edad: 63,
          pctRv: pct,
          tasaRv: 0.03,
          tasaRp: 0.035,
          rentabilidad: 0.035,
          valorUf: _uf,
          aniosCotizados: 25,
        );

    test('30% RV / 70% RP', () {
      final r = sim(0.3);
      expect(r.rvUf, closeTo(5.6999802613663375, 1e-8));
      final f63 = r.filaEdad(63)!;
      expect(f63.rvClp, closeTo(234989.60924739056, 1e-4));
      expect(f63.rpClp, closeTo(576935.982925619, 1e-4));
      expect(f63.pguClp, 0);
      expect(f63.bacClp, 0);
      final f65 = r.filaEdad(65)!;
      expect(f65.pguClp, closeTo(244786.45022280506, 1e-3));
      expect(f65.bacClp, closeTo(103065.975, 1e-6));
      expect(f65.totalClp, closeTo(1147155.20404765, 1e-3));
      expect(r.filaEdad(85)!.totalClp, closeTo(855335.7267134831, 1e-3));
    });

    test('50% y 70%', () {
      final r50 = sim(0.5);
      expect(r50.filaEdad(63)!.totalClp, closeTo(803746.4794068073, 1e-3));
      expect(r50.filaEdad(75)!.totalClp, closeTo(1073448.128979685, 1e-3));
      final r70 = sim(0.7);
      expect(r70.filaEdad(63)!.rvClp, closeTo(548309.0882439113, 1e-4));
      expect(r70.filaEdad(85)!.totalClp, closeTo(1016080.8385865228, 1e-3));
    });

    test('el retiro programado baja con los años y la RV queda fija', () {
      final r = sim(0.5);
      expect(r.filaEdad(75)!.rpClp, lessThan(r.filaEdad(65)!.rpClp));
      expect(r.filaEdad(85)!.rvClp, closeTo(r.filaEdad(63)!.rvClp, 1e-6));
    });

    test('mujer de 60 (BAC con el mínimo del script)', () {
      final r = simularRvInmediataConRp(
        saldoClp: 80000000,
        edad: 60,
        pctRv: 0.5,
        tasaRv: 0.03,
        tasaRp: 0.0367,
        rentabilidad: 0.035,
        valorUf: 41152.13,
        aniosCotizados: 12,
        minimoAnios: 20,
      );
      expect(r.rvUf, closeTo(5.023660191165737, 1e-8));
      expect(r.filaEdad(60)!.totalClp, closeTo(429171.0619300378, 1e-3));
      expect(r.filaEdad(65)!.totalClp, closeTo(667155.8554993693, 1e-3));
      expect(r.filaEdad(80)!.totalClp, closeTo(592738.4366835769, 1e-3));
    });

    test('100% a retiro programado y 100% a renta vitalicia', () {
      final rp = sim(0.0);
      expect(rp.rvUf, 0);
      final rv = sim(1.0);
      expect(rv.filaEdad(70)!.rpClp, 0);
    });

    test('rechaza datos inválidos', () {
      expect(() => simularRvInmediataConRp(
            saldoClp: 0, edad: 63, pctRv: 0.5, tasaRv: 0.03, tasaRp: 0.035,
            rentabilidad: 0.035, valorUf: _uf, aniosCotizados: 25),
          throwsA(isA<ModalidadesMixtasException>()));
      expect(() => simularRvInmediataConRp(
            saldoClp: 1e8, edad: 63, pctRv: 1.5, tasaRv: 0.03, tasaRp: 0.035,
            rentabilidad: 0.035, valorUf: _uf, aniosCotizados: 25),
          throwsA(isA<ModalidadesMixtasException>()));
    });
  });

  group('Renta Temporal con Renta Vitalicia Diferida', () {
    test('caso base del cliente (hombre 63, 2 años, 150%)', () {
      final r = simularRentaTemporalVitalicia(
        saldoClp: 140000000, edad: 63, aniosTemporal: 2, relacion: 1.5,
        tasa: 0.03, valorUf: _uf, aniosCotizados: 25,
      );
      expect(r.temporalUf, closeTo(26.723105723605208, 1e-8));
      expect(r.vitalicioUf, closeTo(17.815403815736804, 1e-8));
      expect(r.temporalClp, closeTo(1101697.1785725805, 1e-3));
      expect(r.vitalicioClp, closeTo(734464.7857150537, 1e-3));
      expect(r.pguClp, 250275);
      expect(r.bacClp, closeTo(103065.975, 1e-6));
      expect(r.totalDesdeVitalicioClp, closeTo(1087805.7607150536, 1e-3));
      expect(r.edadInicioVitalicia, 65);
    });

    test('otro caso: 60 años, 3 años temporal, 200%, 20 años cotizados', () {
      final r = simularRentaTemporalVitalicia(
        saldoClp: 140000000, edad: 60, aniosTemporal: 3, relacion: 2.0,
        tasa: 0.025, valorUf: _uf, aniosCotizados: 20,
      );
      expect(r.temporalUf, closeTo(28.30920949195238, 1e-8));
      expect(r.vitalicioUf, closeTo(14.15460474597619, 1e-8));
      expect(r.bacClp, closeTo(82452.78, 1e-4));
      expect(r.totalDesdeVitalicioClp, closeTo(916271.0355534654, 1e-3));
    });

    test('la renta temporal es "relación" veces la vitalicia', () {
      final r = simularRentaTemporalVitalicia(
        saldoClp: 100000000, edad: 63, aniosTemporal: 2, relacion: 1.0,
        tasa: 0.03, valorUf: _uf, aniosCotizados: 0,
      );
      expect(r.temporalUf, closeTo(r.vitalicioUf, 1e-9));
      expect(r.bacClp, 0);
    });

    test('rechaza datos inválidos', () {
      expect(() => simularRentaTemporalVitalicia(
            saldoClp: 1e8, edad: 63, aniosTemporal: 0, relacion: 1.5,
            tasa: 0.03, valorUf: _uf, aniosCotizados: 25),
          throwsA(isA<ModalidadesMixtasException>()));
    });
  });

  group('PGU y BAC', () {
    const p = ParametrosPguBac();
    test('PGU completa, proporcional y cero', () {
      expect(calcularPgu(700000, p), 250275);
      expect(calcularPgu(1300000, p), 0);
      expect(calcularPgu((789139 + 1252602) / 2, p), closeTo(125137.5, 1e-6));
    });
    test('BAC con mínimo distinto por sexo', () {
      expect(calcularBacUf(19, minimoAniosBac('Hombre'), p), 0);
      expect(calcularBacUf(10, minimoAniosBac('Mujer'), p), closeTo(1.0, 1e-9));
      expect(calcularBacUf(30, minimoAniosBac('Hombre'), p), closeTo(2.5, 1e-9));
    });
  });
}
