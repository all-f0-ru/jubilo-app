import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modelos del flujo "Simular mi pensión" y de la sección "Modalidades".
/// Por ahora esta simulación es orientativa/educativa (no usa el motor
/// de cálculo actuarial real que se está portando aparte en
/// core/pension_engine) — así se lo comunicamos siempre al usuario con
/// un InfoBanner antes de mostrar resultados.

/// Respuestas de la persona a las 4 preguntas del simulador. La edad se
/// pide como rango (no como número exacto) para que la pregunta sea más
/// rápida de responder y calce con el resto de la segmentación de la
/// app.
class SimuladorRespuestas {
  final String rangoEdad; // '55 o menos' | '56 a 60' | '61 a 64' | '65 o más'
  final String sexo; // 'Mujer' | 'Hombre'
  final String estadoCivil; // 'Soltero/a' | 'Casado/a' | 'Viudo/a' | 'Divorciado/a'
  final bool tieneHijos;

  const SimuladorRespuestas({
    required this.rangoEdad,
    required this.sexo,
    required this.estadoCivil,
    required this.tieneHijos,
  });
}

const List<String> rangosEdadSimulador = [
  '55 o menos',
  '56 a 60',
  '61 a 64',
  '65 o más',
];

/// Información (educativa, no calculada) de una modalidad de pensión.
class ModalidadInfo {
  final String id;
  final String nombre;
  final String resumen;
  final String idealPara;
  final IconData icono;
  final Color color;
  final List<String> comoFunciona;
  final List<String> ventajas;
  final List<String> desventajas;

  const ModalidadInfo({
    required this.id,
    required this.nombre,
    required this.resumen,
    required this.idealPara,
    required this.icono,
    required this.color,
    required this.comoFunciona,
    required this.ventajas,
    required this.desventajas,
  });
}

final List<ModalidadInfo> modalidadesPension = [
  ModalidadInfo(
    id: 'retiro_programado',
    nombre: 'Retiro Programado',
    resumen: 'Mantienes tus fondos en la AFP y recibes una pensión mensual '
        'que se recalcula cada año.',
    idealPara: 'Si quieres flexibilidad y mantener el control de tu dinero.',
    icono: Icons.trending_up_rounded,
    color: AppColors.teal,
    comoFunciona: [
      'Tu ahorro se queda invertido en tu AFP.',
      'Cada año se recalcula cuánto puedes retirar mensualmente, según '
          'tu saldo, tu edad y la de tus beneficiarios.',
      'El monto mensual puede subir o bajar de un año a otro.',
    ],
    ventajas: [
      'Mantienes la propiedad de tus fondos.',
      'Puedes cambiar a Renta Vitalicia después, si cumples los requisitos.',
      'Si falleces sin beneficiarios de pensión, el saldo que queda pasa a '
          'tus herederos.',
    ],
    desventajas: [
      'El monto puede bajar con los años, a medida que se usan los fondos.',
      'Depende de la rentabilidad de tus fondos en la AFP.',
      'Tú asumes el riesgo de longevidad.',
    ],
  ),
  ModalidadInfo(
    id: 'renta_vitalicia_inmediata',
    nombre: 'Renta Vitalicia Inmediata',
    resumen: 'Traspasas tus fondos a una aseguradora y recibes una '
        'pensión mensual de por vida.',
    idealPara: 'Si buscas tranquilidad y un ingreso seguro de por vida.',
    icono: Icons.verified_user_outlined,
    color: AppColors.coral,
    comoFunciona: [
      'Traspasas todo tu ahorro a una compañía de seguros de tu elección.',
      'La compañía se compromete a pagarte un monto fijo, todos los '
          'meses, por el resto de tu vida.',
    ],
    ventajas: [
      'Pensión fija y de por vida, sin importar cuánto vivas.',
      'No te preocupas por la rentabilidad.',
      'Puedes incluir pensión de sobrevivencia.',
    ],
    desventajas: [
      'Pierdes la propiedad de tus fondos.',
      'La pensión no sube con la inflación (salvo cláusulas).',
      'La decisión es irreversible.',
    ],
  ),
  ModalidadInfo(
    id: 'renta_temporal_vitalicia_diferida',
    nombre: 'Renta Temporal con Renta Vitalicia Diferida',
    resumen: 'Recibes una renta por un período y luego una pensión '
        'vitalicia diferida de por vida.',
    idealPara: 'Si quieres un ingreso ahora y una pensión mayor más '
        'adelante.',
    icono: Icons.schedule_rounded,
    color: AppColors.teal,
    comoFunciona: [
      'Una parte de tu ahorro queda en la AFP, pagándote un monto mensual '
          'durante un período definido (renta temporal).',
      'Otra parte se traspasa a una compañía de seguros, que empezará a '
          'pagarte una renta vitalicia fija después de ese período.',
    ],
    ventajas: [
      'Combinas un ingreso inmediato con una pensión futura segura.',
      'La renta vitalicia diferida suele ser mayor al postergar.',
      'Bueno si quieres esperar una edad mayor para la pensión final.',
    ],
    desventajas: [
      'Mayor complejidad en la decisión.',
      'Debes coordinar bien los plazos.',
      'Menos flexibilidad una vez elegida.',
    ],
  ),
  ModalidadInfo(
    id: 'renta_vitalicia_con_retiro_programado',
    nombre: 'Renta Vitalicia Inmediata con Retiro Programado',
    resumen: 'Combinas ambas: parte a aseguradora (pensión fija) y parte '
        'en AFP (retiros flexibles).',
    idealPara: 'Si quieres seguridad y a la vez mantener algo de control.',
    icono: Icons.swap_horizontal_circle_outlined,
    color: AppColors.coral,
    comoFunciona: [
      'Una parte de tu ahorro se traspasa a una compañía de seguros, que '
          'te paga un monto fijo mensual de por vida.',
      'La otra parte se queda en tu AFP bajo retiro programado, con un '
          'monto que se recalcula cada año.',
    ],
    ventajas: [
      'Tienes una pensión segura de por vida.',
      'Mantienes parte de tus fondos con flexibilidad.',
      'Equilibra seguridad y control.',
    ],
    desventajas: [
      'La parte en retiro programado baja con el tiempo.',
      'Decisión más compleja de calcular.',
    ],
  ),
];

/// Devuelve las 4 modalidades ordenadas según una sugerencia orientativa
/// (no es un cálculo real) basada en las respuestas del simulador. Es
/// una guía educativa con criterio simple, no un resultado financiero
/// exacto — eso requiere el motor actuarial real, todavía en desarrollo.
List<ModalidadInfo> ordenarModalidadesPara(SimuladorRespuestas r) {
  final puntajes = <String, int>{
    for (final m in modalidadesPension) m.id: 0,
  };

  void sumar(String id, int puntos) {
    puntajes[id] = (puntajes[id] ?? 0) + puntos;
  }

  final edadAlta = r.rangoEdad == '61 a 64' || r.rangoEdad == '65 o más';
  final casadoOConviviente = r.estadoCivil == 'Casado/a';

  // Mayor edad o estado civil con beneficiario → valora más la certeza
  // de un ingreso fijo de por vida.
  if (edadAlta) {
    sumar('renta_vitalicia_inmediata', 2);
    sumar('renta_vitalicia_con_retiro_programado', 1);
  } else {
    sumar('retiro_programado', 2);
    sumar('renta_temporal_vitalicia_diferida', 1);
  }

  // Con hijos o cónyuge → valora dejar herencia / pensión de
  // sobrevivencia.
  if (r.tieneHijos || casadoOConviviente) {
    sumar('retiro_programado', 1);
    sumar('renta_vitalicia_inmediata', 1);
  }

  if (casadoOConviviente) {
    sumar('renta_vitalicia_con_retiro_programado', 1);
  }

  final ordenadas = [...modalidadesPension];
  ordenadas.sort((a, b) => (puntajes[b.id] ?? 0).compareTo(puntajes[a.id] ?? 0));
  return ordenadas;
}
