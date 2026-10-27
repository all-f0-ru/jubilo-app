/// Parámetros externos del cálculo de pensiones, con fecha y fuente.
///
/// Se concentran acá (y no dentro de las fórmulas) para actualizarlos sin
/// tocar la lógica actuarial. Cada valor indica de dónde salió y a qué
/// fecha corresponde, para poder auditarlo.
library;

import 'renta_vitalicia.dart';

class ParametrosVigentes {
  ParametrosVigentes._();

  // -------------------------------------------------------------------
  // Tasa de referencia de rentas vitalicias de vejez
  // -------------------------------------------------------------------

  /// 2,81 % anual (en decimal).
  static const double tasaReferenciaVejez = 0.0281;

  static const String tasaFuente =
      'Comisión para el Mercado Financiero, publicada por la '
      'Superintendencia de Pensiones: tasa de interés promedio implícita de '
      'las rentas vitalicias de vejez (Ley 21.419). Promedio febrero-julio '
      '2026, aplicable al mes de agosto 2026.';

  /// Fecha en que se consultó la tabla.
  static final DateTime tasaFechaConsulta = DateTime(2026, 10, 13);

  // -------------------------------------------------------------------
  // Tasa del Retiro Programado
  // -------------------------------------------------------------------

  /// 3,67 % anual (en decimal): Tasa de Interés Técnica de Retiro Programado
  /// y Rentas Temporales, vigente desde el 1 de octubre de 2026.
  /// Historial reciente: 3,41 % (oct-2025), 3,31 % (ene-2026), 3,45 %
  /// (jul-2026), 3,67 % (oct-2026). Cambia por circular, normalmente cada
  /// trimestre: hay que actualizarla cuando la Superintendencia publique una
  /// nueva (spensiones.cl > Tasas de interés para retiros programados).
  static const double tasaRetiroProgramado = 0.0367;

  /// Si vuelve a ser true, la pantalla avisa que la tasa es provisoria.
  static const bool tasaRetiroProgramadoProvisoria = false;

  static final DateTime tasaRetiroProgramadoDesde = DateTime(2026, 10, 1);

  static const String tasaRetiroProgramadoFuente =
      'Superintendencia de Pensiones, Circular N° 2425 (2 de octubre de '
      '2026): tasa de interés para el cálculo y recálculo de retiros '
      'programados y rentas temporales, vigente desde el 1 de octubre de '
      '2026.';

  // -------------------------------------------------------------------
  // Valor de la UF
  // -------------------------------------------------------------------

  /// Valor de la UF al 13-10-2026 (fuente: SII).
  static const double valorUf = 41152.13;

  static final DateTime valorUfFecha = DateTime(2026, 10, 13);

  static const String valorUfFuente =
      'Servicio de Impuestos Internos (sii.cl), valores diarios de la UF.';

  /// Tasa de referencia lista para usar en [ParametrosRvi].
  static TasaReferenciaRvi get tasaReferencia => TasaReferenciaRvi(
        valor: tasaReferenciaVejez,
        tipo: TipoTasaRvi.vejez,
        fechaCalculo: tasaFechaConsulta,
        fuente: tasaFuente,
      );
}
