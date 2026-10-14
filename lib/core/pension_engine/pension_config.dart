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
