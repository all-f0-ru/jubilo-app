import 'simulacion_guardada.dart';

/// Una modalidad dentro de una comparativa guardada.
class FilaComparativa {
  /// Una de las constantes de [SimulacionGuardada] (rentaVitalicia, etc.).
  final String modalidad;
  final double montoClp;
  final double montoUf;

  /// Aportes del Estado estimados (0 si no corresponden).
  final double pguClp;
  final double bacClp;

  const FilaComparativa({
    required this.modalidad,
    required this.montoClp,
    required this.montoUf,
    this.pguClp = 0,
    this.bacClp = 0,
  });

  double get totalClp => montoClp + pguClp + bacClp;

  String get nombre {
    switch (modalidad) {
      case SimulacionGuardada.retiroProgramado:
        return 'Retiro Programado';
      case SimulacionGuardada.temporalVitalicia:
        return 'Renta Temporal + Vitalicia Diferida';
      case SimulacionGuardada.rvConRp:
        return 'Renta Vitalicia + Retiro Programado';
      default:
        return 'Renta Vitalicia';
    }
  }

  Map<String, dynamic> toJson() => {
        'modalidad': modalidad,
        'montoClp': montoClp,
        'montoUf': montoUf,
        'pguClp': pguClp,
        'bacClp': bacClp,
      };

  factory FilaComparativa.fromJson(Map<String, dynamic> j) => FilaComparativa(
        modalidad: j['modalidad'] as String,
        montoClp: (j['montoClp'] as num).toDouble(),
        montoUf: (j['montoUf'] as num).toDouble(),
        pguClp: (j['pguClp'] as num? ?? 0).toDouble(),
        bacClp: (j['bacClp'] as num? ?? 0).toDouble(),
      );
}

/// Una comparativa de modalidades que la persona decidió guardar (Premium):
/// los datos que usó y lo que dio cada modalidad en ese momento.
class ComparativaGuardada {
  final String id;
  final DateTime fecha;
  final int saldoClp;
  final int edad;
  final String sexo;
  final int aniosCotizados;
  final bool conConyuge;
  final int cantidadHijos;
  final double valorUf;
  final List<FilaComparativa> filas;

  const ComparativaGuardada({
    required this.id,
    required this.fecha,
    required this.saldoClp,
    required this.edad,
    required this.sexo,
    required this.aniosCotizados,
    required this.conConyuge,
    required this.cantidadHijos,
    required this.valorUf,
    required this.filas,
  });

  /// La modalidad que más da al mes (monto al pensionarte), si hay filas.
  FilaComparativa? get mayor {
    if (filas.isEmpty) return null;
    return filas.reduce((a, b) => b.montoClp > a.montoClp ? b : a);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'saldoClp': saldoClp,
        'edad': edad,
        'sexo': sexo,
        'aniosCotizados': aniosCotizados,
        'conConyuge': conConyuge,
        'cantidadHijos': cantidadHijos,
        'valorUf': valorUf,
        'filas': filas.map((f) => f.toJson()).toList(),
      };

  factory ComparativaGuardada.fromJson(Map<String, dynamic> j) =>
      ComparativaGuardada(
        id: j['id'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        saldoClp: (j['saldoClp'] as num).toInt(),
        edad: (j['edad'] as num).toInt(),
        sexo: j['sexo'] as String,
        aniosCotizados: (j['aniosCotizados'] as num? ?? 0).toInt(),
        conConyuge: j['conConyuge'] as bool? ?? false,
        cantidadHijos: (j['cantidadHijos'] as num? ?? 0).toInt(),
        valorUf: (j['valorUf'] as num).toDouble(),
        filas: [
          for (final f in (j['filas'] as List))
            FilaComparativa.fromJson(Map<String, dynamic>.from(f as Map)),
        ],
      );
}
