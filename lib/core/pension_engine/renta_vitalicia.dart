/// Renta Vitalicia Inmediata (RVI) simple — port a Dart de
/// `renta_vitalicia.py` V5.0 del cliente.
///
/// Es una referencia actuarial, NO una cotización comercial de una
/// compañía de seguros.
///
/// Fórmula:
///   factor mensual      = CNU * 12
///   pensión mensual UF  = prima UF / (CNU * 12)
///   pensión mensual CLP = pensión UF * valor UF
///
/// El CNU del grupo familiar se calcula con `calcularCnuTotal`
/// (cnu_grupo.dart). Este archivo no duplica fórmulas de mortalidad.
///
/// ALCANCE: RVI inmediata simple, sin período garantizado, sin aumento
/// temporal y sin condiciones especiales. Beneficiarios admitidos hoy:
/// un cónyuge sin hijos (ver cnu_grupo.dart).
library;

import 'cnu_engine.dart';
import 'cnu_grupo.dart';

/// Error propio del módulo RVI (equivale a `RentaVitaliciaError`).
class RentaVitaliciaException implements Exception {
  final String message;
  RentaVitaliciaException(this.message);

  @override
  String toString() => 'RentaVitaliciaException: $message';
}

enum EscenarioRvi { vejez, vejezAnticipada, invalidez }

enum TipoTasaRvi { vejez, invalidez }

/// Fecha desde la cual el umbral mínimo de contratación baja de 3 a 2 UF.
final DateTime fechaCambioUmbralRvi = DateTime(2025, 9, 1);

/// Umbral legal mínimo (en UF) para contratar una RVI, según la fecha.
double umbralMinimoRviUf(DateTime fecha) {
  return !fecha.isBefore(fechaCambioUmbralRvi) ? 2.0 : 3.0;
}

/// Tasa de referencia trazable (promedio de 6 meses). No es una cotización.
class TasaReferenciaRvi {
  /// Tasa anual en decimal. Ej.: 0,0281 = 2,81 %.
  final double valor;
  final TipoTasaRvi tipo;
  final DateTime fechaCalculo;
  final String fuente;
  final int mesesConsiderados;

  const TasaReferenciaRvi({
    required this.valor,
    required this.tipo,
    required this.fechaCalculo,
    required this.fuente,
    this.mesesConsiderados = 6,
  });

  double validar() {
    if (valor.isNaN || valor.isInfinite) {
      throw RentaVitaliciaException('La tasa normativa RVI debe ser finita.');
    }
    if (valor <= -1) {
      throw RentaVitaliciaException(
        'La tasa normativa RVI no puede ser menor o igual a -100%.',
      );
    }
    if (mesesConsiderados != 6) {
      throw RentaVitaliciaException(
        'La tasa de referencia exige una ventana de seis meses.',
      );
    }
    if (fuente.trim().isEmpty) {
      throw RentaVitaliciaException(
        'La fuente de la tasa normativa es obligatoria.',
      );
    }
    return valor;
  }
}

/// Beneficiario descrito por fecha de nacimiento (la edad se calcula).
class BeneficiarioRvi {
  /// Hoy solo 'conyuge'.
  final String tipo;

  /// 'M' | 'F'
  final String sexo;
  final DateTime fechaNacimiento;
  final bool invalido;

  const BeneficiarioRvi({
    required this.tipo,
    required this.sexo,
    required this.fechaNacimiento,
    this.invalido = false,
  });
}

class GrupoFamiliarRvi {
  /// 'M' | 'F'
  final String afiliadoSexo;
  final DateTime afiliadoFechaNacimiento;
  final bool afiliadoInvalido;
  final List<BeneficiarioRvi> beneficiarios;

  const GrupoFamiliarRvi({
    required this.afiliadoSexo,
    required this.afiliadoFechaNacimiento,
    this.afiliadoInvalido = false,
    this.beneficiarios = const [],
  });
}

class ParametrosRvi {
  /// En RVI inmediata coincide con la fecha de pensión.
  final DateTime fechaReferencia;
  final TasaReferenciaRvi tasaReferencia;
  final EscenarioRvi escenario;
  final String version;

  const ParametrosRvi({
    required this.fechaReferencia,
    required this.tasaReferencia,
    this.escenario = EscenarioRvi.vejez,
    this.version = 'RVI-5.0-dart',
  });

  int get calculationYear => fechaReferencia.year;

  double get tasaRentaVitalicia => tasaReferencia.validar();

  void validar() {
    tasaReferencia.validar();
    if (tasaReferencia.tipo == TipoTasaRvi.vejez &&
        escenario == EscenarioRvi.invalidez) {
      throw RentaVitaliciaException(
        'Una RVI de invalidez debe utilizar tasa normativa de invalidez.',
      );
    }
    if (tasaReferencia.tipo == TipoTasaRvi.invalidez &&
        escenario != EscenarioRvi.invalidez) {
      throw RentaVitaliciaException(
        'Una RVI de vejez debe utilizar tasa normativa de vejez.',
      );
    }
  }
}

/// Resultado con valores económicos, actuariales y de auditoría.
class ResultadoRentaVitalicia {
  // Económico
  final double primaUf;
  final double pensionMensualUf;
  final double pensionMensualClp;
  final double valorUf;

  // Actuarial
  final double cnuTotal;
  final double cnuAfiliado;
  final double cnuConyuge;
  final double factorAnual;
  final double factorMensual;

  // Contexto y tasa
  final DateTime fechaReferencia;
  final EscenarioRvi escenario;
  final double tasaRentaVitalicia;
  final TipoTasaRvi tipoTasa;
  final String fuenteTasa;

  // Auditoría
  final String version;
  final double umbralMinimoUf;
  final bool cumpleUmbralMinimo;
  final List<String> observaciones;

  const ResultadoRentaVitalicia({
    required this.primaUf,
    required this.pensionMensualUf,
    required this.pensionMensualClp,
    required this.valorUf,
    required this.cnuTotal,
    required this.cnuAfiliado,
    required this.cnuConyuge,
    required this.factorAnual,
    required this.factorMensual,
    required this.fechaReferencia,
    required this.escenario,
    required this.tasaRentaVitalicia,
    required this.tipoTasa,
    required this.fuenteTasa,
    required this.version,
    required this.umbralMinimoUf,
    required this.cumpleUmbralMinimo,
    required this.observaciones,
  });
}

/// Edad en años cumplidos (igual que `_edad` en renta_vitalicia.py).
int _edadCumplida(DateTime nacimiento, DateTime referencia) {
  var edad = referencia.year - nacimiento.year;
  final aunNoCumple = referencia.month < nacimiento.month ||
      (referencia.month == nacimiento.month && referencia.day < nacimiento.day);
  if (aunNoCumple) edad -= 1;
  return edad;
}

String _normalizarSexo(String sexo, String quien) {
  final s = sexo.toUpperCase();
  if (s != 'M' && s != 'F') {
    throw RentaVitaliciaException('El sexo del $quien debe ser M o F.');
  }
  return s;
}

/// Adaptador RVI -> núcleo CNU (equivale a `construir_grupo_cnu`).
GrupoFamiliarCnu construirGrupoCnu(
  GrupoFamiliarRvi grupo,
  DateTime fechaReferencia,
) {
  final sexoAfiliado = _normalizarSexo(grupo.afiliadoSexo, 'afiliado');
  if (grupo.afiliadoFechaNacimiento.isAfter(fechaReferencia)) {
    throw RentaVitaliciaException(
      'El afiliado no puede nacer después de la fecha de referencia.',
    );
  }

  final beneficiarios = <BeneficiarioCnu>[];
  for (final b in grupo.beneficiarios) {
    final sexo = _normalizarSexo(b.sexo, 'beneficiario');
    if (b.fechaNacimiento.isAfter(fechaReferencia)) {
      throw RentaVitaliciaException(
        'El beneficiario no puede nacer después de la fecha de referencia.',
      );
    }
    beneficiarios.add(
      BeneficiarioCnu(
        tipo: b.tipo,
        sexo: sexo,
        edad: _edadCumplida(b.fechaNacimiento, fechaReferencia),
        invalido: b.invalido,
      ),
    );
  }

  return GrupoFamiliarCnu(
    afiliadoSexo: sexoAfiliado,
    afiliadoEdad: _edadCumplida(grupo.afiliadoFechaNacimiento, fechaReferencia),
    afiliadoInvalido: grupo.afiliadoInvalido,
    beneficiarios: beneficiarios,
  );
}

/// Calcula una RVI inmediata simple.
///
/// [tablas] son las 5 tablas TM2020 (ver tm2020_loader.dart).
ResultadoRentaVitalicia calcularRentaVitalicia({
  required double primaUf,
  required GrupoFamiliarRvi grupoFamiliar,
  required ParametrosRvi parametros,
  required double valorUf,
  required Map<String, MortalityTable> tablas,
}) {
  if (primaUf.isNaN || primaUf.isInfinite || primaUf <= 0) {
    throw RentaVitaliciaException('La prima UF debe ser mayor que cero.');
  }
  if (valorUf.isNaN || valorUf.isInfinite || valorUf <= 0) {
    throw RentaVitaliciaException('El valor UF debe ser mayor que cero.');
  }

  parametros.validar();

  final grupoCnu = construirGrupoCnu(grupoFamiliar, parametros.fechaReferencia);

  final cnu = calcularCnuTotal(
    grupo: grupoCnu,
    tablas: tablas,
    calculationYear: parametros.calculationYear,
    interestRate: parametros.tasaRentaVitalicia,
  );

  // Igual que en Python: el factor anual es el CNU total ya redondeado.
  final factorAnual = cnu.cnuTotal;
  if (factorAnual.isNaN || factorAnual.isInfinite || factorAnual <= 0) {
    throw RentaVitaliciaException('CNU/factor RVI inválido: $factorAnual');
  }
  final factorMensual = factorAnual * 12.0;

  final pensionUf = primaUf / factorMensual;
  final pensionClp = pensionUf * valorUf;
  final umbral = umbralMinimoRviUf(parametros.fechaReferencia);
  final cumple = pensionUf >= umbral;

  return ResultadoRentaVitalicia(
    primaUf: primaUf,
    pensionMensualUf: pensionUf,
    pensionMensualClp: pensionClp,
    valorUf: valorUf,
    cnuTotal: cnu.cnuTotal,
    cnuAfiliado: cnu.cnuAfiliado,
    cnuConyuge: cnu.cnuConyuge,
    factorAnual: factorAnual,
    factorMensual: factorMensual,
    fechaReferencia: parametros.fechaReferencia,
    escenario: parametros.escenario,
    tasaRentaVitalicia: parametros.tasaRentaVitalicia,
    tipoTasa: parametros.tasaReferencia.tipo,
    fuenteTasa: parametros.tasaReferencia.fuente,
    version: parametros.version,
    umbralMinimoUf: umbral,
    cumpleUmbralMinimo: cumple,
    observaciones: [
      'RVI inmediata simple de referencia actuarial.',
      'El factor anual corresponde al CNU del grupo familiar.',
      'El factor mensual corresponde a CNU x 12.',
      'La tasa es una tasa de referencia de seis meses.',
      'El resultado no constituye una oferta comercial de una compañía de seguros.',
      'Umbral mínimo aplicable: ${umbral.toStringAsFixed(2)} UF; cumple=$cumple.',
      'No se incorporan condiciones especiales de cobertura.',
    ],
  );
}
