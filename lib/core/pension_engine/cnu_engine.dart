/// Port a Dart de `cnu_V4_0.py` (motor de Capital Necesario Unitario).
///
/// ESTADO: PORTADO PARCIALMENTE — solo el caso base "afiliado solo, sin
/// beneficiarios" (equivalente a `cnu_afiliado()` en el archivo Python
/// original). El resto de las funciones (cónyuge, hijos, hijos inválidos,
/// conviviente civil, acrecimiento múltiple, sobrevivencia) todavía NO
/// están portadas — se agregan de a poco en próximas reuniones, siguiendo
/// el mismo archivo fuente `cnu_V4_0.py` línea por línea.
///
/// IMPORTANTE: este motor no trae datos reales. Las tablas TM2020
/// (qx e improvement) deben cargarse desde los CSV oficiales que entregue
/// el supervisor — acá solo se define la estructura para recibirlas
/// (ver [MortalityTable] y el TODO en la parte inferior de este archivo).
///
/// Fuente de referencia normativa (según el docstring del archivo Python
/// original): Superintendencia de Pensiones, Nota Técnica N°9,
/// noviembre 2024; Compendio de Normas del Sistema de Pensiones, Libro
/// III, Título X; Tablas de Mortalidad TM2020.
library;

/// Equivalente a `CNUError` en Python.
class CNUException implements Exception {
  final String message;
  CNUException(this.message);

  @override
  String toString() => 'CNUException: $message';
}

// ---------------------------------------------------------------------
// Constantes (idénticas a las de cnu_V4_0.py)
// ---------------------------------------------------------------------

const int tableMaxAge = 110;
const int childMaxAge = 23;
const double monthlyAdjustment = 11.0 / 24.0;
const int tm2020BaseYear = 2020;
const int tm2020FirstImprovementYear = 2021;
const int tm2020LastDynamicYear = 2036;
const int cnuDecimals = 6;

const Set<String> supportedTables = {
  'CB-H-2020',
  'MI-H-2020',
  'RV-M-2020',
  'B-M-2020',
  'MI-M-2020',
};

// ---------------------------------------------------------------------
// MortalityTable — equivalente a la dataclass MortalityTable de Python
// ---------------------------------------------------------------------

/// Una tabla TM2020.
///
/// [qx] : q_x del año base 2020, una probabilidad por cada edad
/// 0..[maxAge].
///
/// [improvement] : improvement[edad][año] = AA_(x,t). La probabilidad
/// mejorada se calcula como:
///
///   q_(x,año) = q_(x,2020) * producto(1 - AA_(x,t)) para t = 2021..año
///
/// Desde el año 2036 en adelante se usa el factor publicado para 2036.
class MortalityTable {
  final String name;
  final Map<int, double> qx;
  final Map<int, Map<int, double>> improvement;
  final int baseYear;
  final int maxAge;
  final int lastDynamicYear;

  MortalityTable({
    required this.name,
    required this.qx,
    required this.improvement,
    this.baseYear = tm2020BaseYear,
    this.maxAge = tableMaxAge,
    this.lastDynamicYear = tm2020LastDynamicYear,
  }) {
    _validate();
  }

  void _validate() {
    if (!supportedTables.contains(name)) {
      throw CNUException('Tabla no soportada: $name');
    }

    final expected = Set<int>.from(List.generate(maxAge + 1, (i) => i));
    final actual = qx.keys.toSet();

    if (!_setEquals(actual, expected)) {
      final missing = expected.difference(actual).toList()..sort();
      final extra = actual.difference(expected).toList()..sort();
      throw CNUException(
        '$name: qx debe cubrir edades 0..$maxAge. '
        'Faltantes=$missing; extras=$extra',
      );
    }

    for (final entry in qx.entries) {
      if (entry.value < 0.0 || entry.value > 1.0) {
        throw CNUException('$name: qx inválido en edad ${entry.key}: ${entry.value}');
      }
    }

    for (final ageEntry in improvement.entries) {
      final age = ageEntry.key;
      if (!expected.contains(age)) {
        throw CNUException('$name: edad AA inválida: $age');
      }
      for (final yearEntry in ageEntry.value.entries) {
        final year = yearEntry.key;
        final aa = yearEntry.value;
        if (year < baseYear + 1) {
          throw CNUException('$name: año AA inválido: $year');
        }
        if (aa < 0.0 || aa >= 1.0) {
          throw CNUException('$name: AA($age,$year) inválido: $aa');
        }
      }
    }
  }

  static bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  /// Devuelve AA(x,t), usando AA(x,2036) desde 2036 en adelante.
  double aa(int age, int year) {
    validateAge(age, maxAge: maxAge);

    if (year <= baseYear) return 0.0;

    final effectiveYear = year < lastDynamicYear ? year : lastDynamicYear;
    final row = improvement[age] ?? const {};

    if (!row.containsKey(effectiveYear)) {
      throw CNUException('No existe AA($age,$effectiveYear) para $name');
    }

    return row[effectiveYear]!;
  }

  /// q_x mejorada para el año de cálculo, usando los factores TM2020.
  double improvedQ(int age, int calculationYear) {
    validateAge(age, maxAge: maxAge);

    if (calculationYear <= baseYear) {
      return qx[age]!;
    }

    var q = qx[age]!;

    for (var year = baseYear + 1; year <= calculationYear; year++) {
      q *= 1.0 - aa(age, year);
    }

    if (q < 0.0) return 0.0;
    if (q > 1.0) return 1.0;
    return q;
  }
}

// ---------------------------------------------------------------------
// Funciones auxiliares (equivalentes a las de cnu_V4_0.py)
// ---------------------------------------------------------------------

/// Redondea un CNU al número de decimales exigido para salida normativa.
double redondearCnu(double valor) {
  final factor = 1.0 * _pow10(cnuDecimals);
  return (valor * factor).round() / factor;
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

void _validateCalculationYear(int calculationYear) {
  if (calculationYear < tm2020BaseYear) {
    throw CNUException(
      'calculation_year=$calculationYear no es compatible con TM2020. '
      'Use un año >= $tm2020BaseYear.',
    );
  }
}

void validateAge(int age, {int maxAge = tableMaxAge}) {
  if (age < 0 || age > maxAge) {
    throw CNUException('Edad fuera de rango: $age; rango permitido 0..$maxAge.');
  }
}

/// Edad actuarial aproximada al entero más cercano.
int edadActuarial({
  required DateTime fechaNacimiento,
  required DateTime fechaCalculo,
}) {
  if (fechaCalculo.isBefore(fechaNacimiento)) {
    throw CNUException('fecha_calculo no puede ser anterior a fecha_nacimiento');
  }

  final dias = fechaCalculo.difference(fechaNacimiento).inDays;
  final edadDecimal = dias / 365.2425;
  final edad = (edadDecimal + 0.5).floor();

  if (edad < 0) return 0;
  if (edad > tableMaxAge) return tableMaxAge;
  return edad;
}

/// i_t. Si se entrega un solo double, se usa la misma tasa para todo t.
/// Si se entrega una `List<double>`, interestRate[t] es i_t.
double rateAt(Object interestRate, int t) {
  if (t < 0) {
    throw CNUException('t no puede ser negativo.');
  }

  double rate;
  if (interestRate is num) {
    rate = interestRate.toDouble();
  } else if (interestRate is List<num>) {
    if (t >= interestRate.length) {
      throw CNUException('No existe tasa i_$t en el vector entregado.');
    }
    rate = interestRate[t].toDouble();
  } else {
    throw CNUException('interestRate debe ser num o List<num>.');
  }

  if (rate <= -1.0) {
    throw CNUException('La tasa de interés debe ser > -100%.');
  }

  return rate;
}

/// Factor de descuento v_t = 1 / (1+i_t)^t.
double presentValueFactor(Object interestRate, int t) {
  final r = rateAt(interestRate, t);
  return 1.0 / _powDouble(1.0 + r, t);
}

double _powDouble(double base, int exp) {
  var result = 1.0;
  for (var i = 0; i < exp; i++) {
    result *= base;
  }
  return result;
}

/// l_(x+t) / l_x para t años.
double survivalRatio({
  required MortalityTable table,
  required int startAge,
  required int years,
  required int calculationYear,
}) {
  validateAge(startAge, maxAge: table.maxAge);

  if (years < 0) {
    throw CNUException('years no puede ser negativo.');
  }

  if (startAge + years > table.maxAge) {
    return 0.0;
  }

  var survival = 1.0;

  for (var age = startAge; age < startAge + years; age++) {
    final year = calculationYear + (age - startAge);
    final q = table.improvedQ(age, year);
    survival *= 1.0 - q;
  }

  return survival;
}

/// Σ [l_(x+t)/l_x] / (1+i_t)^t.
double discountedSurvivalSum({
  required MortalityTable table,
  required int age,
  required int calculationYear,
  required Object interestRate,
  int? endAge,
}) {
  validateAge(age, maxAge: table.maxAge);

  var effectiveEndAge = endAge ?? table.maxAge;
  if (effectiveEndAge > table.maxAge) effectiveEndAge = table.maxAge;

  if (effectiveEndAge < age) return 0.0;

  var total = 0.0;

  for (var t = 0; t <= effectiveEndAge - age; t++) {
    final survival = survivalRatio(
      table: table,
      startAge: age,
      years: t,
      calculationYear: calculationYear,
    );
    total += survival * presentValueFactor(interestRate, t);
  }

  return total;
}

/// Selección de tabla TM2020 según normativa:
/// - Afiliado hombre no inválido -> CB-H-2020
/// - Afiliado hombre inválido -> MI-H-2020
/// - Afiliada mujer no inválida -> RV-M-2020
/// - Afiliada mujer inválida -> MI-M-2020
/// - Beneficiario hombre no inválido -> CB-H-2020
/// - Beneficiaria mujer no inválida -> B-M-2020
/// - Inválido (cualquiera) -> MI-H/M-2020
String tablaOficial(
  String sexo, {
  bool invalido = false,
  bool beneficiario = false,
}) {
  final s = sexo.toUpperCase();
  if (s != 'M' && s != 'F') {
    throw CNUException('sexo debe ser M o F');
  }

  if (invalido) {
    return s == 'M' ? 'MI-H-2020' : 'MI-M-2020';
  }

  if (beneficiario) {
    return s == 'M' ? 'CB-H-2020' : 'B-M-2020';
  }

  return s == 'M' ? 'CB-H-2020' : 'RV-M-2020';
}

/// CNU del afiliado solo, sin beneficiarios.
///
/// Ecuación (9) de la Nota Técnica N°9:
///   CNU_i = Σ [l_(x+t)/l_x] / (1+i_t)^t  -  11/24
double cnuAfiliado({
  required int edad,
  required MortalityTable tabla,
  required int calculationYear,
  required Object interestRate,
}) {
  _validateCalculationYear(calculationYear);

  final base = discountedSurvivalSum(
    table: tabla,
    age: edad,
    calculationYear: calculationYear,
    interestRate: interestRate,
  );

  final result = base - monthlyAdjustment;
  return result > 0.0 ? result : 0.0;
}

// ---------------------------------------------------------------------
// TODO (próximas reuniones, según se reciban los archivos/tablas):
// - Carga de tablas TM2020 desde CSV oficiales (cargarTablaCsv,
//   cargarTablasTm2020 en el Python original).
// - cnu_conyuge_sin_hijos, cnu_conyuge_con_hijos (CNU con cónyuge).
// - cnu_hijo / cnu_hijo_invalido (CNU con hijos, con y sin invalidez).
// - conviviente civil, madre/padre causante, acrecimiento múltiple.
// - calcular_cnu_total (función que integra todos los casos).
// - Los módulos bac.py, bono_hijo.py, pgu.py, eld.py, proyeccion_rp.py,
//   cev.py y retiro_programado_V5.py (aún no entregados).
// ---------------------------------------------------------------------
