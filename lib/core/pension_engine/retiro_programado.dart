/// Retiro Programado (RP), cálculo base — port a Dart de
/// `retiro_programado.py` V5.0 del cliente.
///
/// Es una referencia actuarial educativa, NO el cálculo oficial de una AFP.
///
/// Fórmula (anualidad base, un solo fondo):
///   denominador         = CNU + z / 12
///   anualidad UF        = saldo UF / denominador
///   pensión mensual UF  = anualidad UF / 12
///   pensión mensual CLP = pensión UF * valor UF
///
/// El CNU se calcula con `calcularCnuTotal` (cnu_grupo.dart), igual que en
/// la Renta Vitalicia, pero usando la tasa propia del Retiro Programado.
///
/// ALCANCE: solo la pensión base del primer año. En la realidad el monto se
/// recalcula cada año. BAC, Bono por Hijo, PGU, ELD, CEV y la proyección de
/// años siguientes NO están incluidos (los módulos aún no fueron entregados
/// por el cliente). Los 9 registros del saldo se tratan como un solo saldo.
library;

import 'cnu_engine.dart';
import 'cnu_grupo.dart';
import 'renta_vitalicia.dart';

/// Error propio del módulo RP (equivale a `RetiroProgramadoError`).
class RetiroProgramadoException implements Exception {
  final String message;
  RetiroProgramadoException(this.message);

  @override
  String toString() => 'RetiroProgramadoException: $message';
}

class ParametrosRp {
  final DateTime fechaReferencia;

  /// Tasa anual de Retiro Programado en decimal. Ej.: 0,0331 = 3,31 %.
  final double tasaRp;

  /// Identifica de dónde sale la tasa (obligatorio, para auditar).
  final String versionTasa;

  /// z: pensiones devengadas pendientes. En el simulador siempre 0.
  final int pensionesDevengadasPendientes;

  final String version;

  const ParametrosRp({
    required this.fechaReferencia,
    required this.tasaRp,
    required this.versionTasa,
    this.pensionesDevengadasPendientes = 0,
    this.version = 'RP-5.0-dart',
  });

  int get calculationYear => fechaReferencia.year;

  void validar() {
    if (tasaRp.isNaN || tasaRp.isInfinite || tasaRp <= -1) {
      throw RetiroProgramadoException('Tasa RP inválida.');
    }
    if (versionTasa.trim().isEmpty) {
      throw RetiroProgramadoException(
        'versionTasa debe identificar la tasa utilizada.',
      );
    }
    if (pensionesDevengadasPendientes < 0) {
      throw RetiroProgramadoException(
        'Las pensiones devengadas pendientes no pueden ser negativas.',
      );
    }
  }
}

class ResultadoRetiroProgramado {
  // Económico
  final double saldoTotalUf;
  final double anualidadUf;
  final double anualidadClp;
  final double pensionMensualUf;
  final double pensionMensualClp;
  final double valorUf;

  // Actuarial
  final double cnuTotal;
  final double cnuAfiliado;
  final double cnuConyuge;
  final int z;
  final double denominador;

  // Contexto
  final DateTime fechaReferencia;
  final double tasaRp;
  final String versionTasa;

  // Auditoría
  final String version;
  final List<String> observaciones;

  const ResultadoRetiroProgramado({
    required this.saldoTotalUf,
    required this.anualidadUf,
    required this.anualidadClp,
    required this.pensionMensualUf,
    required this.pensionMensualClp,
    required this.valorUf,
    required this.cnuTotal,
    required this.cnuAfiliado,
    required this.cnuConyuge,
    required this.z,
    required this.denominador,
    required this.fechaReferencia,
    required this.tasaRp,
    required this.versionTasa,
    required this.version,
    required this.observaciones,
  });
}

/// Calcula la pensión base de Retiro Programado (primer año).
///
/// [tablas] son las 5 tablas TM2020 (ver tm2020_loader.dart). El grupo
/// familiar es el mismo de la RVI: el afiliado y, si corresponde, un cónyuge.
ResultadoRetiroProgramado calcularRetiroProgramado({
  required double saldoUf,
  required GrupoFamiliarRvi grupoFamiliar,
  required ParametrosRp parametros,
  required double valorUf,
  required Map<String, MortalityTable> tablas,
}) {
  if (saldoUf.isNaN || saldoUf.isInfinite || saldoUf <= 0) {
    throw RetiroProgramadoException('El saldo UF debe ser mayor que cero.');
  }
  if (valorUf.isNaN || valorUf.isInfinite || valorUf <= 0) {
    throw RetiroProgramadoException('El valor UF debe ser mayor que cero.');
  }

  parametros.validar();

  final grupoCnu = construirGrupoCnu(grupoFamiliar, parametros.fechaReferencia);

  final cnu = calcularCnuTotal(
    grupo: grupoCnu,
    tablas: tablas,
    calculationYear: parametros.calculationYear,
    interestRate: parametros.tasaRp,
  );

  final cnuTotal = cnu.cnuTotal;
  if (cnuTotal.isNaN || cnuTotal.isInfinite || cnuTotal <= 0) {
    throw RetiroProgramadoException('CNU debe ser positivo: $cnuTotal');
  }

  final z = parametros.pensionesDevengadasPendientes;
  final denominador = cnuTotal + z / 12.0;

  final anualidadUf = saldoUf / denominador;
  final pensionUf = anualidadUf / 12.0;

  return ResultadoRetiroProgramado(
    saldoTotalUf: saldoUf,
    anualidadUf: anualidadUf,
    anualidadClp: anualidadUf * valorUf,
    pensionMensualUf: pensionUf,
    pensionMensualClp: pensionUf * valorUf,
    valorUf: valorUf,
    cnuTotal: cnuTotal,
    cnuAfiliado: cnu.cnuAfiliado,
    cnuConyuge: cnu.cnuConyuge,
    z: z,
    denominador: denominador,
    fechaReferencia: parametros.fechaReferencia,
    tasaRp: parametros.tasaRp,
    versionTasa: parametros.versionTasa,
    version: parametros.version,
    observaciones: [
      'Retiro Programado: pensión base del primer año.',
      'La anualidad es saldo / (CNU + z/12); la pensión mensual es anualidad / 12.',
      'El monto se recalcula cada año según saldo, edad y beneficiarios.',
      'No incluye BAC, Bono por Hijo, PGU, ELD, CEV ni proyección.',
      'Tasa RP utilizada: ${parametros.versionTasa}.',
      'El resultado no es el cálculo oficial de una AFP.',
    ],
  );
}
