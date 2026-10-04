/// Modelos del flujo "Simular mi pensión". Por ahora esta simulación es
/// orientativa/educativa (no usa el motor de cálculo actuarial real que
/// se está portando aparte en core/pension_engine) — así se lo
/// comunicamos siempre al usuario con un InfoBanner antes de mostrar
/// resultados.
library;

/// Respuestas de la persona a las 4 preguntas del simulador.
class SimuladorRespuestas {
  final int edad;
  final String sexo; // 'Mujer' | 'Hombre'
  final String estadoCivil; // 'Soltero/a' | 'Casado/a' | 'Viudo/a' | 'Divorciado/a'
  final bool tieneHijos;

  const SimuladorRespuestas({
    required this.edad,
    required this.sexo,
    required this.estadoCivil,
    required this.tieneHijos,
  });
}

/// Información (educativa, no calculada) de una modalidad de pensión.
class ModalidadInfo {
  final String id;
  final String nombre;
  final String resumen;
  final List<String> comoFunciona;
  final List<String> ventajas;
  final List<String> consideraciones;

  const ModalidadInfo({
    required this.id,
    required this.nombre,
    required this.resumen,
    required this.comoFunciona,
    required this.ventajas,
    required this.consideraciones,
  });
}

final List<ModalidadInfo> modalidadesPension = [
  ModalidadInfo(
    id: 'retiro_programado',
    nombre: 'Retiro Programado',
    resumen: 'Mantienes tu ahorro en la AFP y retiras un monto mensual '
        'que se recalcula cada año.',
    comoFunciona: [
      'Tu ahorro se queda invertido en tu AFP.',
      'Cada año se recalcula cuánto puedes retirar mensualmente, según '
          'tu saldo, tu edad y la de tus beneficiarios.',
      'El monto mensual puede subir o bajar de un año a otro.',
    ],
    ventajas: [
      'Si falleces, el saldo que quede es herencia para tus beneficiarios.',
      'Puedes cambiarte a otra modalidad más adelante si cambia tu situación.',
    ],
    consideraciones: [
      'El monto mensual no es fijo: puede variar según el rendimiento '
          'de tu fondo.',
      'Existe el riesgo de que el ahorro se agote si vives muchos años '
          'más de lo esperado.',
    ],
  ),
  ModalidadInfo(
    id: 'renta_vitalicia_inmediata',
    nombre: 'Renta Vitalicia Inmediata',
    resumen: 'Traspasas tu ahorro a una compañía de seguros, que te paga '
        'un monto fijo mensual de por vida.',
    comoFunciona: [
      'Traspasas todo tu ahorro a una compañía de seguros de tu elección.',
      'La compañía se compromete a pagarte un monto fijo, todos los '
          'meses, por el resto de tu vida.',
    ],
    ventajas: [
      'El monto mensual es fijo y no cambia, dándote certeza.',
      'No importa cuántos años vivas: el pago está garantizado.',
    ],
    consideraciones: [
      'Una vez elegida, en general no se puede cambiar a otra modalidad.',
      'Si falleces, no queda saldo como herencia (salvo beneficios '
          'pactados para tus beneficiarios).',
    ],
  ),
  ModalidadInfo(
    id: 'renta_temporal_vitalicia_diferida',
    nombre: 'Renta Temporal con Renta Vitalicia Diferida',
    resumen: 'Recibes un pago temporal desde tu AFP mientras esperas que '
        'comience una renta vitalicia fija.',
    comoFunciona: [
      'Una parte de tu ahorro queda en la AFP, pagándote un monto mensual '
          'durante un período definido (renta temporal).',
      'Otra parte se traspasa a una compañía de seguros, que empezará a '
          'pagarte una renta vitalicia fija después de ese período.',
    ],
    ventajas: [
      'Combina flexibilidad al inicio con seguridad de pago fijo a '
          'futuro.',
      'Si falleces durante el período temporal, el saldo restante es '
          'herencia.',
    ],
    consideraciones: [
      'Es una modalidad más compleja de entender y comparar.',
      'El monto de la renta temporal puede variar en ese período inicial.',
    ],
  ),
  ModalidadInfo(
    id: 'renta_vitalicia_con_retiro_programado',
    nombre: 'Renta Vitalicia Inmediata con Retiro Programado',
    resumen: 'Combina una parte fija de por vida con otra parte variable '
        'que administras tú desde tu AFP.',
    comoFunciona: [
      'Una parte de tu ahorro se traspasa a una compañía de seguros, que '
          'te paga un monto fijo mensual de por vida.',
      'La otra parte se queda en tu AFP bajo retiro programado, con un '
          'monto que se recalcula cada año.',
    ],
    ventajas: [
      'Tienes una base fija garantizada, más una parte flexible.',
      'El saldo que quede en la parte de retiro programado es herencia.',
    ],
    consideraciones: [
      'Requiere entender y seguir dos componentes distintos de tu '
          'pensión.',
      'La parte de retiro programado sigue teniendo el mismo riesgo de '
          'variación que esa modalidad por sí sola.',
    ],
  ),
];
