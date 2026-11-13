import 'dart:math' as math;

/// Cálculos de las dos modalidades combinadas, portados de los scripts del
/// cliente:
///   - simulador_rv_inmediata_retiro_programado.py
///   - simulador_renta_temporal_vitalicia.py
///
/// IMPORTANTE: igual que en los scripts del cliente, la mortalidad es una
/// curva de Gompertz calibrada a una esperanza de vida de 19,5 años a los 65
/// (NO las tablas oficiales TM2020 que usan Renta Vitalicia Inmediata y
/// Retiro Programado). Por eso son estimaciones referenciales. Tampoco
/// consideran beneficiarios, comisiones ni márgenes de las aseguradoras.
class ModalidadesMixtasException implements Exception {
  final String mensaje;
  ModalidadesMixtasException(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Parámetros de PGU y BAC vigentes en 2026 (se reajustan cada año).
class ParametrosPguBac {
  final double pguMaxima;
  final double pensionInferior; // hasta aquí la PGU es completa
  final double pensionSuperior; // desde aquí la PGU es 0
  final double bacUfPorAnio;
  final int bacTopeAnios;

  const ParametrosPguBac({
    this.pguMaxima = 250275,
    this.pensionInferior = 789139,
    this.pensionSuperior = 1252602,
    this.bacUfPorAnio = 0.1,
    this.bacTopeAnios = 25,
  });
}

/// Parámetros vigentes de PGU y BAC. Se pueden actualizar sin publicar la
/// app (vienen de Firebase); si no hay conexión se usan los del código.
ParametrosPguBac parametrosPguBacActual = const ParametrosPguBac();

const double _bGompertz = 0.095;

/// Edad máxima (inclusive) hasta la que un hijo/a tiene derecho a pensión,
/// igual que en el cálculo oficial del cliente (cnu_rv_v20.py).
const int edadMaximaHijo = 23;
const int maximoHijos = 6;

double Function(double) _supervivencia(double a, double x0) {
  return (double t) => math.exp(
      -(a / _bGompertz) * math.exp(_bGompertz * x0) *
          (math.exp(_bGompertz * t) - 1));
}

/// Busca el parámetro 'a' de Gompertz para que e(65) sea [e65].
double calibrarGompertz(int edad, {double e65 = 19.5}) {
  double esp65(double a) {
    final s = _supervivencia(a, edad.toDouble());
    final t0 = 65.0 - edad;
    final base = s(t0);
    var suma = 0.0;
    for (var m = 0; m < 12 * 60; m++) {
      suma += s(t0 + m / 12 + 1 / 24) / base / 12;
    }
    return suma;
  }

  var lo = 1e-7;
  var hi = 1e-3;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    if (esp65(mid) > e65) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Valor presente de 1 unidad mensual vitalicia (pago vencido) a [edad].
double factorAnualidadGompertz(double a, double edad, double tasa) {
  final s = _supervivencia(a, edad);
  final im = math.pow(1 + tasa, 1 / 12).toDouble() - 1;
  var suma = 0.0;
  for (var k = 1; k < 12 * 65; k++) {
    suma += s(k / 12) / math.pow(1 + im, k);
  }
  return suma;
}

void _validarHijos(List<int> edades) {
  if (edades.length > maximoHijos) {
    throw ModalidadesMixtasException(
        'Se pueden considerar hasta $maximoHijos hijos/as.');
  }
  for (final h in edades) {
    if (h < 0 || h > edadMaximaHijo) {
      throw ModalidadesMixtasException(
          'Los hijos/as con derecho a pensión tienen entre 0 y '
          '$edadMaximaHijo años.');
    }
  }
}

/// Costo adicional de la pensión de los hijos/as, por unidad de pensión
/// mensual del afiliado. Aproximación referencial:
///   - Sin cónyuge (D.L. 3.500, art. 58 y cnu_rv_v20.py del cliente): cada
///     hijo/a con derecho recibe 15% de la pensión, más el 50% que se
///     reparte en partes iguales entre los hijos/as (15% + 50% / n),
///     desde el fallecimiento del afiliado y hasta los 23 años cumplidos
///     (hijos de 18 a 23 años se suponen estudiando).
///   - Se ignora la mortalidad de los hijos/as.
///   - Solo se cuentan los pagos desde el mes [desdeMes] + 1.
/// [s] es la supervivencia del afiliado medida desde el inicio de la
/// pensión y [im] la tasa mensual.
double _terminoHijos(double Function(double) s, double im, List<int> edades,
    {int desdeMes = 0}) {
  final activos = edades.where((h) => h >= 0 && h <= edadMaximaHijo).toList();
  if (activos.isEmpty) return 0.0;
  final porcentaje = 0.15 + 0.50 / activos.length;
  var total = 0.0;
  for (final h in activos) {
    final hasta = math.min(12 * (edadMaximaHijo + 1 - h), 12 * 65 - 1);
    for (var k = desdeMes + 1; k <= hasta; k++) {
      total += porcentaje * (1 - s(k / 12)) / math.pow(1 + im, k);
    }
  }
  return total;
}

/// Igual que [factorAnualidadGompertz], pero sumando el costo de la pensión
/// de los hijos/as ([hijosEdades] medidas hoy, a la edad [edad]).
double factorConHijosGompertz(
    double a, double edad, double tasa, List<int> hijosEdades) {
  final base = factorAnualidadGompertz(a, edad, tasa);
  if (hijosEdades.isEmpty) return base;
  final s = _supervivencia(a, edad);
  final im = math.pow(1 + tasa, 1 / 12).toDouble() - 1;
  return base + _terminoHijos(s, im, hijosEdades);
}

double calcularPgu(double pensionBase, ParametrosPguBac p) {
  if (pensionBase <= p.pensionInferior) return p.pguMaxima;
  if (pensionBase >= p.pensionSuperior) return 0.0;
  return p.pguMaxima *
      (p.pensionSuperior - pensionBase) /
      (p.pensionSuperior - p.pensionInferior);
}

/// BAC mensual en UF. Mínimo de años cotizados: 20 hombres, 10 mujeres.
double calcularBacUf(double aniosCotizados, int minimoAnios, ParametrosPguBac p) {
  if (aniosCotizados < minimoAnios) return 0.0;
  return p.bacUfPorAnio * math.min(aniosCotizados, p.bacTopeAnios.toDouble());
}

int minimoAniosBac(String sexo) => sexo == 'Mujer' ? 10 : 20;

// ---------------------------------------------------------------------------
// Renta Vitalicia Inmediata con Retiro Programado
// ---------------------------------------------------------------------------

class FilaRvRp {
  final int edad;
  final double rvUf;
  final double rpUf;
  final double rvClp;
  final double rpClp;
  final double pguClp;
  final double bacClp;
  final double totalClp;
  final double saldoRpClp;

  const FilaRvRp({
    required this.edad,
    required this.rvUf,
    required this.rpUf,
    required this.rvClp,
    required this.rpClp,
    required this.pguClp,
    required this.bacClp,
    required this.totalClp,
    required this.saldoRpClp,
  });
}

class ResultadoRvRp {
  final double saldoUf;
  final double pctRv;
  final double rvUf;
  final double valorUf;
  final List<FilaRvRp> filas;

  const ResultadoRvRp({
    required this.saldoUf,
    required this.pctRv,
    required this.rvUf,
    required this.valorUf,
    required this.filas,
  });

  FilaRvRp? filaEdad(int edad) {
    for (final f in filas) {
      if (f.edad == edad) return f;
    }
    return null;
  }
}

ResultadoRvRp simularRvInmediataConRp({
  required double saldoClp,
  required int edad,
  required double pctRv,
  required double tasaRv,
  required double tasaRp,
  required double rentabilidad,
  required double valorUf,
  required double aniosCotizados,
  int minimoAnios = 20,
  int horizonte = 90,
  List<int> hijosEdades = const [],
  ParametrosPguBac pgu = const ParametrosPguBac(),
}) {
  _validarHijos(hijosEdades);
  if (saldoClp <= 0) {
    throw ModalidadesMixtasException('El saldo debe ser mayor que cero.');
  }
  if (pctRv < 0 || pctRv > 1) {
    throw ModalidadesMixtasException('El porcentaje debe estar entre 0 y 100%.');
  }
  if (edad < 50 || edad > 65) {
    throw ModalidadesMixtasException(
        'Esta simulación es para quienes se pensionan entre 50 y 65 años.');
  }

  final a = calibrarGompertz(edad);
  final saldoUf = saldoClp / valorUf;

  final primaRv = saldoUf * pctRv;
  final rvUf = primaRv > 0
      ? primaRv / factorConHijosGompertz(a, edad.toDouble(), tasaRv, hijosEdades)
      : 0.0;

  var bal = saldoUf * (1 - pctRv);
  final imReal = math.pow(1 + rentabilidad, 1 / 12).toDouble() - 1;
  final bacUf = calcularBacUf(aniosCotizados, minimoAnios, pgu);

  final filas = <FilaRvRp>[];
  for (var x = edad; x <= horizonte; x++) {
    // Los hijos/as van creciendo: los que pasan de 23 años dejan de contar.
    final hijosX = hijosEdades
        .map((h) => h + (x - edad))
        .where((h) => h <= edadMaximaHijo)
        .toList();
    final rpUf = bal > 0
        ? bal / factorConHijosGompertz(a, x.toDouble(), tasaRp, hijosX)
        : 0.0;
    final saldoActualUf = bal;
    for (var i = 0; i < 12; i++) {
      bal = bal * (1 + imReal) - rpUf;
      bal = math.max(bal, 0.0);
    }
    final rvClp = rvUf * valorUf;
    final rpClp = rpUf * valorUf;
    final extraPgu = x >= 65 ? calcularPgu(rvClp + rpClp, pgu) : 0.0;
    final extraBac = x >= 65 ? bacUf * valorUf : 0.0;
    filas.add(FilaRvRp(
      edad: x,
      rvUf: rvUf,
      rpUf: rpUf,
      rvClp: rvClp,
      rpClp: rpClp,
      pguClp: extraPgu,
      bacClp: extraBac,
      totalClp: rvClp + rpClp + extraPgu + extraBac,
      saldoRpClp: saldoActualUf * valorUf,
    ));
  }

  return ResultadoRvRp(
    saldoUf: saldoUf,
    pctRv: pctRv,
    rvUf: rvUf,
    valorUf: valorUf,
    filas: filas,
  );
}

// ---------------------------------------------------------------------------
// Renta Temporal con Renta Vitalicia Diferida
// ---------------------------------------------------------------------------

class ResultadoTemporalVitalicia {
  final double saldoUf;
  final double temporalUf;
  final double temporalClp;
  final double vitalicioUf;
  final double vitalicioClp;
  final double pguClp;
  final double bacClp;
  final double totalDesdeVitalicioClp;
  final int edadInicioVitalicia;
  final int aniosTemporal;
  final double relacion;
  final double valorUf;

  const ResultadoTemporalVitalicia({
    required this.saldoUf,
    required this.temporalUf,
    required this.temporalClp,
    required this.vitalicioUf,
    required this.vitalicioClp,
    required this.pguClp,
    required this.bacClp,
    required this.totalDesdeVitalicioClp,
    required this.edadInicioVitalicia,
    required this.aniosTemporal,
    required this.relacion,
    required this.valorUf,
  });
}

ResultadoTemporalVitalicia simularRentaTemporalVitalicia({
  required double saldoClp,
  required int edad,
  required int aniosTemporal,
  required double relacion,
  required double tasa,
  required double valorUf,
  required double aniosCotizados,
  int minimoAnios = 20,
  double? pensionBaseClp,
  List<int> hijosEdades = const [],
  ParametrosPguBac pgu = const ParametrosPguBac(),
}) {
  _validarHijos(hijosEdades);
  if (saldoClp <= 0) {
    throw ModalidadesMixtasException('El saldo debe ser mayor que cero.');
  }
  if (edad < 50 || edad > 65) {
    throw ModalidadesMixtasException(
        'Esta simulación es para quienes se pensionan entre 50 y 65 años.');
  }
  if (aniosTemporal < 1 || aniosTemporal > 10) {
    throw ModalidadesMixtasException(
        'La renta temporal debe durar entre 1 y 10 años.');
  }
  if (relacion <= 0) {
    throw ModalidadesMixtasException('La relación debe ser mayor que cero.');
  }

  final a = calibrarGompertz(edad);
  final s = _supervivencia(a, edad.toDouble());
  final saldoUf = saldoClp / valorUf;
  final im = math.pow(1 + tasa, 1 / 12).toDouble() - 1;
  final n = aniosTemporal * 12;

  var fTemporal = 0.0;
  for (var k = 1; k <= n; k++) {
    fTemporal += 1 / math.pow(1 + im, k);
  }
  var fVitalicia = 0.0;
  for (var k = n + 1; k < 12 * 60; k++) {
    fVitalicia += s(k / 12) / math.pow(1 + im, k);
  }

  // Costo de la pensión de los hijos/as, solo desde que parte la vitalicia.
  fVitalicia += _terminoHijos(s, im, hijosEdades, desdeMes: n);

  final vitalicioUf = saldoUf / (relacion * fTemporal + fVitalicia);
  final temporalUf = relacion * vitalicioUf;
  final vit = vitalicioUf * valorUf;
  final temp = temporalUf * valorUf;
  final base = pensionBaseClp ?? vit;
  final pguClp = calcularPgu(base, pgu);
  final bacClp = calcularBacUf(aniosCotizados, minimoAnios, pgu) * valorUf;

  return ResultadoTemporalVitalicia(
    saldoUf: saldoUf,
    temporalUf: temporalUf,
    temporalClp: temp,
    vitalicioUf: vitalicioUf,
    vitalicioClp: vit,
    pguClp: pguClp,
    bacClp: bacClp,
    totalDesdeVitalicioClp: vit + pguClp + bacClp,
    edadInicioVitalicia: edad + aniosTemporal,
    aniosTemporal: aniosTemporal,
    relacion: relacion,
    valorUf: valorUf,
  );
}
