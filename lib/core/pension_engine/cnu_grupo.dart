/// CNU del grupo familiar (equivale a `calcular_cnu_total` del Python).
///
/// ALCANCE ACTUAL: afiliado solo, o afiliado con UN cónyuge sin hijos.
/// Cualquier otra estructura (hijos, conviviente civil, madre/padre,
/// varios cónyuges, beneficiarios inválidos) se rechaza con un error
/// explícito: no se aproxima con otra fórmula parecida, igual que hace el
/// motor Python original.
library;

import 'cnu_engine.dart';

/// Beneficiario del afiliado. Hoy solo se admite `tipo == 'conyuge'`.
class BeneficiarioCnu {
  /// 'conyuge' (los demás tipos aún no están portados).
  final String tipo;

  /// 'M' (hombre) o 'F' (mujer).
  final String sexo;

  /// Edad en años cumplidos a la fecha de cálculo.
  final int edad;

  final bool invalido;

  const BeneficiarioCnu({
    required this.tipo,
    required this.sexo,
    required this.edad,
    this.invalido = false,
  });
}

/// Afiliado y sus beneficiarios con derecho.
class GrupoFamiliarCnu {
  final String afiliadoSexo; // 'M' | 'F'
  final int afiliadoEdad;
  final bool afiliadoInvalido;
  final List<BeneficiarioCnu> beneficiarios;

  const GrupoFamiliarCnu({
    required this.afiliadoSexo,
    required this.afiliadoEdad,
    this.afiliadoInvalido = false,
    this.beneficiarios = const [],
  });
}

/// Resultado del CNU, con cada componente por separado (trazabilidad).
class CnuResultado {
  final double cnuTotal;
  final double cnuAfiliado;
  final double cnuConyuge;
  final String tablaAfiliado;
  final String? tablaConyuge;
  final int calculationYear;
  final double interestRate;
  final List<String> warnings;

  const CnuResultado({
    required this.cnuTotal,
    required this.cnuAfiliado,
    required this.cnuConyuge,
    required this.tablaAfiliado,
    required this.tablaConyuge,
    required this.calculationYear,
    required this.interestRate,
    this.warnings = const [],
  });
}

MortalityTable _requerirTabla(
  Map<String, MortalityTable> tablas,
  String nombre,
) {
  final t = tablas[nombre];
  if (t == null) {
    throw CNUException('Falta la tabla TM2020 requerida: $nombre');
  }
  return t;
}

/// Calcula el CNU total del grupo familiar.
///
/// Como en Python, el cálculo interno mantiene precisión completa y solo
/// los valores expuestos se redondean a 6 decimales.
CnuResultado calcularCnuTotal({
  required GrupoFamiliarCnu grupo,
  required Map<String, MortalityTable> tablas,
  required int calculationYear,
  required double interestRate,
}) {
  if (calculationYear < tm2020BaseYear) {
    throw CNUException(
      'calculation_year=$calculationYear no es compatible con TM2020. '
      'Use un año >= $tm2020BaseYear.',
    );
  }
  rateAt(interestRate, 0); // valida que la tasa sea > -100%

  final sexoAfiliado = grupo.afiliadoSexo.toUpperCase();
  validateAge(grupo.afiliadoEdad);

  // Estructuras permitidas por ahora.
  final conyuges = <BeneficiarioCnu>[];
  for (final b in grupo.beneficiarios) {
    if (b.tipo != 'conyuge') {
      throw CNUException(
        'Beneficiario "${b.tipo}" todavía no está portado a Dart. '
        'Se agrega en una próxima etapa; no se aproxima.',
      );
    }
    if (b.invalido) {
      throw CNUException(
        'Cónyuge inválido todavía no está portado a Dart; no se aproxima.',
      );
    }
    conyuges.add(b);
  }
  if (conyuges.length > 1) {
    throw CNUException(
      'Múltiples cónyuges requieren la ecuación de acrecimiento, '
      'todavía no portada a Dart; no se aproxima.',
    );
  }

  final nombreTablaA = tablaOficial(
    sexoAfiliado,
    invalido: grupo.afiliadoInvalido,
    beneficiario: false,
  );
  final tablaA = _requerirTabla(tablas, nombreTablaA);

  final cnuA = cnuAfiliado(
    edad: grupo.afiliadoEdad,
    tabla: tablaA,
    calculationYear: calculationYear,
    interestRate: interestRate,
  );

  var cnuC = 0.0;
  String? nombreTablaC;

  if (conyuges.isNotEmpty) {
    final c = conyuges.first;
    validateAge(c.edad);
    nombreTablaC = tablaOficial(c.sexo, invalido: false, beneficiario: true);
    final tablaC = _requerirTabla(tablas, nombreTablaC);

    // Ecuación (10) de la Nota Técnica N°9 (sin la resta 11/24).
    cnuC = cnuConyugeSinHijos(
      edadAfiliado: grupo.afiliadoEdad,
      edadConyuge: c.edad,
      tablaAfiliado: tablaA,
      tablaConyuge: tablaC,
      calculationYear: calculationYear,
      interestRate: interestRate,
    );
  }

  return CnuResultado(
    cnuTotal: redondearCnu(cnuA + cnuC),
    cnuAfiliado: redondearCnu(cnuA),
    cnuConyuge: redondearCnu(cnuC),
    tablaAfiliado: nombreTablaA,
    tablaConyuge: nombreTablaC,
    calculationYear: calculationYear,
    interestRate: interestRate,
    warnings: const [
      'CNU expuesto con 6 decimales; el cálculo interno mantiene '
          'precisión completa.',
    ],
  );
}
