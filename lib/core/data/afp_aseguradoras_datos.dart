/// Datos públicos para comparar AFP y mostrar información de aseguradoras.
/// Son datos referenciales: se deben revisar y actualizar cada cierto tiempo.
class AfpDatos {
  AfpDatos._();

  /// Comisión: tabla de octubre 2026 de "Infórmate y Decide" (Superintendencia
  /// de Pensiones). Rentabilidad: real, promedio anual de los últimos 36
  /// meses (ago 2023 - jul 2026), Ficha Estadística N° 165 de la
  /// Superintendencia de Pensiones.
  static const String comisionesPeriodo = 'octubre 2026';
  static const String rentabilidadPeriodo = 'ago 2023 – jul 2026 (36 meses)';

  /// Orden de los valores de [rent36]: fondos A, B, C, D, E.
  static const List<AfpDato> afp = [
    AfpDato('Uno', 0.46, [11.26, 9.33, 5.94, 3.02, 1.12]),
    AfpDato('Modelo', 0.58, [10.95, 9.00, 5.70, 2.55, 0.59]),
    AfpDato('PlanVital', 1.16, [11.14, 9.31, 5.95, 2.93, 1.24]),
    AfpDato('Habitat', 1.27, [10.77, 8.83, 5.75, 2.98, 1.21]),
    AfpDato('Capital', 1.44, [11.10, 9.21, 5.98, 2.95, 1.18]),
    AfpDato('Cuprum', 1.44, [11.26, 9.42, 5.99, 3.06, 1.36]),
    AfpDato('Provida', 1.45, [10.97, 9.02, 5.36, 2.54, 1.00]),
  ];

  static const List<String> fondos = ['A', 'B', 'C', 'D', 'E'];

  /// Participación (%) de pensionados en renta vitalicia por compañía,
  /// julio 2025 – junio 2026 (informe SCOMP primer semestre 2026,
  /// Superintendencia de Pensiones).
  static const String participacionPeriodo = 'jul 2025 – jun 2026';
  static const List<AseguradoraDato> aseguradoras = [
    AseguradoraDato('Penta Vida', 23.0),
    AseguradoraDato('MetLife', 18.1),
    AseguradoraDato('Consorcio Vida', 13.2),
    AseguradoraDato('Bice Vida', 12.9),
    AseguradoraDato('Confuturo', 12.7),
    AseguradoraDato('4 Life Seguros', 8.7),
    AseguradoraDato('Renta Nacional', 6.1),
  ];

  /// Tasa promedio de renta vitalicia del sistema, 1er semestre 2026 (%).
  static const double tasaPromedioRentaVitalicia = 2.8;
}

class AfpDato {
  final String nombre;
  final double comisionPct;
  final List<double> rent36;
  const AfpDato(this.nombre, this.comisionPct, this.rent36);
}

class AseguradoraDato {
  final String nombre;
  final double participacionPct;
  const AseguradoraDato(this.nombre, this.participacionPct);
}
