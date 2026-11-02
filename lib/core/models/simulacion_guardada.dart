/// Una simulación que la persona decidió guardar (función Premium).
/// Guarda el monto que escribió y la hora en que la hizo, junto con el
/// resultado, para poder compararlas y ver la tendencia después.
class SimulacionGuardada {
  static const String rentaVitalicia = 'renta_vitalicia';
  static const String retiroProgramado = 'retiro_programado';
  static const String temporalVitalicia = 'renta_temporal_vitalicia';
  static const String rvConRp = 'rv_con_rp';

  /// Todas las modalidades que se pueden guardar.
  static const List<String> todas = [
    rentaVitalicia,
    retiroProgramado,
    temporalVitalicia,
    rvConRp,
  ];

  /// Id de la modalidad en `modalidadesPension` (para el color, etc.).
  static String idInfo(String modalidad) {
    switch (modalidad) {
      case retiroProgramado:
        return 'retiro_programado';
      case temporalVitalicia:
        return 'renta_temporal_vitalicia_diferida';
      case rvConRp:
        return 'renta_vitalicia_con_retiro_programado';
      default:
        return 'renta_vitalicia_inmediata';
    }
  }

  final String id;
  final DateTime fecha;

  /// [rentaVitalicia] o [retiroProgramado].
  final String modalidad;

  final int saldoClp;
  final int edad;

  /// 'Mujer' | 'Hombre'
  final String sexo;
  final bool conConyuge;

  final double pensionMensualClp;
  final double pensionMensualUf;
  final double valorUf;

  /// Tasa anual en decimal usada en el cálculo (ej. 0,0367).
  final double tasa;

  const SimulacionGuardada({
    required this.id,
    required this.fecha,
    required this.modalidad,
    required this.saldoClp,
    required this.edad,
    required this.sexo,
    required this.conConyuge,
    required this.pensionMensualClp,
    required this.pensionMensualUf,
    required this.valorUf,
    required this.tasa,
  });

  String get nombreModalidad {
    switch (modalidad) {
      case retiroProgramado:
        return 'Retiro Programado';
      case temporalVitalicia:
        return 'Renta Temporal + Vitalicia Diferida';
      case rvConRp:
        return 'Renta Vitalicia + Retiro Programado';
      default:
        return 'Renta Vitalicia';
    }
  }

  /// Texto que acompaña al monto.
  String get bajada {
    switch (modalidad) {
      case retiroProgramado:
        return 'al mes, el primer año';
      case temporalVitalicia:
        return 'al mes, durante la renta temporal';
      case rvConRp:
        return 'al mes, al pensionarte';
      default:
        return 'al mes, de por vida';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'modalidad': modalidad,
        'saldoClp': saldoClp,
        'edad': edad,
        'sexo': sexo,
        'conConyuge': conConyuge,
        'pensionMensualClp': pensionMensualClp,
        'pensionMensualUf': pensionMensualUf,
        'valorUf': valorUf,
        'tasa': tasa,
      };

  factory SimulacionGuardada.fromJson(Map<String, dynamic> j) {
    return SimulacionGuardada(
      id: j['id'] as String,
      fecha: DateTime.parse(j['fecha'] as String),
      modalidad: j['modalidad'] as String,
      saldoClp: (j['saldoClp'] as num).toInt(),
      edad: (j['edad'] as num).toInt(),
      sexo: j['sexo'] as String,
      conConyuge: j['conConyuge'] as bool,
      pensionMensualClp: (j['pensionMensualClp'] as num).toDouble(),
      pensionMensualUf: (j['pensionMensualUf'] as num).toDouble(),
      valorUf: (j['valorUf'] as num).toDouble(),
      tasa: (j['tasa'] as num).toDouble(),
    );
  }
}
