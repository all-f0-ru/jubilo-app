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
  static double _tasaVejez = 0.0281;
  static double get tasaReferenciaVejez => _tasaVejez;

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
  static double _tasaRp = 0.0367;
  static double get tasaRetiroProgramado => _tasaRp;

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
  static double _uf = 41152.13;
  static double get valorUf => _uf;

  static DateTime _ufFecha = DateTime(2026, 10, 13);
  static DateTime get valorUfFecha => _ufFecha;

  static const String valorUfFuente =
      'Servicio de Impuestos Internos (sii.cl), valores diarios de la UF.';

  /// Tasa de referencia lista para usar en [ParametrosRvi].
  static TasaReferenciaRvi get tasaReferencia => TasaReferenciaRvi(
        valor: tasaReferenciaVejez,
        tipo: TipoTasaRvi.vejez,
        fechaCalculo: tasaFechaConsulta,
        fuente: tasaFuente,
      );

  // -------------------------------------------------------------------
  // Rentabilidad real esperada del fondo (retiro programado)
  // -------------------------------------------------------------------

  static double _rentabilidad = 0.035;
  static double get rentabilidadReal => _rentabilidad;

  // -------------------------------------------------------------------
  // Actualización desde internet (ver ParametrosService)
  // -------------------------------------------------------------------

  /// De dónde viene hoy el valor de la UF: 'codigo', 'guardado',
  /// 'firebase' o 'automatico'.
  static String origenUf = 'codigo';

  /// Si las tasas vinieron de Firebase (o de la última copia guardada).
  static bool tasasActualizadas = false;

  /// Aplica valores nuevos. Ignora los que vengan vacíos o fuera de rango,
  /// así un dato mal escrito en Firebase no rompe los cálculos.
  static void aplicar({
    double? tasaVejez,
    double? tasaRp,
    double? rentabilidad,
    double? uf,
    DateTime? ufFecha,
    String? origenDeUf,
  }) {
    if (tasaVejez != null && tasaVejez > 0 && tasaVejez < 0.15) {
      _tasaVejez = tasaVejez;
    }
    if (tasaRp != null && tasaRp > 0 && tasaRp < 0.15) _tasaRp = tasaRp;
    if (rentabilidad != null && rentabilidad > 0 && rentabilidad < 0.15) {
      _rentabilidad = rentabilidad;
    }
    if (uf != null && uf > 10000 && uf < 200000) {
      _uf = uf;
      if (ufFecha != null) _ufFecha = ufFecha;
      if (origenDeUf != null) origenUf = origenDeUf;
    }
  }
}
