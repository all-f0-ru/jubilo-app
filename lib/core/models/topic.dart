import 'package:flutter/material.dart';
import 'user_segment.dart';

/// Término de glosario: palabra previsional + su definición en lenguaje
/// simple. Se muestra como chip tocable dentro del contenido de un tema
/// (pantalla "Contenido de tema"); al tocarlo se abre una hoja inferior
/// con la definición, sin salir de la pantalla.
class GlossaryTerm {
  final String termino;
  final String definicion;

  const GlossaryTerm(this.termino, this.definicion);
}

/// Uno de los 7 temas centrales del flujo "Aprender sobre mi pensión",
/// basados en la guía de contenido entregada por la empresa.
class Topic {
  final String id;
  final String titulo;
  final IconData icono;
  final String resumen;

  /// Párrafos de contenido general (se muestran siempre).
  final List<String> contenido;

  /// Párrafo adicional específico para ciertos segmentos (ej. un
  /// recordatorio distinto si la persona ya está en edad de jubilar).
  final Map<Segmento, String> notaPorSegmento;

  final List<GlossaryTerm> glosario;

  /// Segmentos para los que este tema es especialmente relevante; se usa
  /// para ordenar la lista y mostrar el chip "Relevante para tu etapa".
  final List<Segmento> segmentosRelevantes;

  const Topic({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.resumen,
    required this.contenido,
    this.notaPorSegmento = const {},
    this.glosario = const [],
    this.segmentosRelevantes = const [],
  });
}

/// Los 7 temas centrales de Jubilo.
final List<Topic> topicsJubilo = [
  Topic(
    id: 'que_es_pension',
    titulo: '¿Qué es la pensión y cómo funciona?',
    icono: Icons.menu_book_rounded,
    resumen: 'Una explicación simple del sistema previsional chileno.',
    contenido: [
      'La pensión es el dinero que recibes mensualmente cuando dejas de '
          'trabajar, después de haber ahorrado durante tu vida laboral en '
          'tu AFP (Administradora de Fondos de Pensiones).',
      'Ese dinero no es un regalo del Estado: es el ahorro que tú mismo/a '
          'fuiste formando con un porcentaje de tu sueldo (más la '
          'rentabilidad que ese ahorro generó con el tiempo).',
      'Además del ahorro de tu AFP, existen beneficios del Estado que se '
          'pueden sumar a tu pensión, como la Pensión Garantizada '
          'Universal (PGU).',
    ],
    glosario: const [
      GlossaryTerm('AFP',
          'Administradora de Fondos de Pensiones. Es la institución '
              'privada que guarda e invierte el dinero que ahorras '
              'durante tu vida laboral para tu pensión.'),
      GlossaryTerm('PGU',
          'Pensión Garantizada Universal. Un beneficio del Estado que se '
              'entrega a las personas mayores que cumplen ciertos '
              'requisitos, independiente de cuánto hayan ahorrado.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerPreparacion,
      Segmento.hombrePreparacion,
    ],
  ),
  Topic(
    id: 'ahorro_cotizaciones',
    titulo: 'Tu ahorro y las cotizaciones',
    icono: Icons.savings_outlined,
    resumen: 'Cómo se forma el dinero que vas a recibir.',
    contenido: [
      'Cada mes que trabajas de forma dependiente, tu empleador descuenta '
          'un porcentaje de tu sueldo y lo deposita en tu cuenta de '
          'ahorro individual en tu AFP. A esto se le llama "cotizar".',
      'Mientras más años cotices y mientras mayor sea tu sueldo '
          'imponible, más grande será el ahorro con el que llegarás a tu '
          'pensión.',
      'Puedes revisar cuánto llevas ahorrado en cualquier momento, '
          'entrando al sitio web o la app de tu AFP con tu clave única.',
    ],
    notaPorSegmento: const {
      Segmento.mujerPreparacion:
          'Como todavía te queda tiempo antes de jubilar, cada cotización '
              'que hagas de aquí en adelante sigue aumentando tu ahorro '
              'final.',
      Segmento.hombrePreparacion:
          'Como todavía te queda tiempo antes de jubilar, cada cotización '
              'que hagas de aquí en adelante sigue aumentando tu ahorro '
              'final.',
    },
    glosario: const [
      GlossaryTerm('Cotizar',
          'Aportar un porcentaje de tu sueldo mensual a tu cuenta de '
              'ahorro previsional en la AFP.'),
      GlossaryTerm('Clave única',
          'Tu contraseña personal para hacer trámites en sitios del '
              'Estado de Chile por internet, incluyendo revisar tu AFP.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerPreparacion,
      Segmento.hombrePreparacion,
    ],
  ),
  Topic(
    id: 'edad_legal_requisitos',
    titulo: 'Edad legal y requisitos para jubilar',
    icono: Icons.event_available_outlined,
    resumen: 'Cuándo puedes empezar a pensionarte y qué necesitas.',
    contenido: [
      'En Chile, la edad legal para pensionarse es 60 años para las '
          'mujeres y 65 años para los hombres.',
      'Cumplir la edad legal no te obliga a jubilar de inmediato: puedes '
          'seguir trabajando y cotizando si lo prefieres, y pensionarte '
          'más adelante con un ahorro mayor.',
      'Para solicitar tu pensión necesitas tu cédula de identidad '
          'vigente, tu clave única, y la información de tu AFP a mano.',
    ],
    glosario: const [
      GlossaryTerm('Edad legal',
          'La edad mínima que define la ley para poder empezar a recibir '
              'una pensión de vejez: 60 años en mujeres, 65 en hombres.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerEvaluacion,
      Segmento.hombreEvaluacion,
    ],
  ),
  Topic(
    id: 'modalidades_pension',
    titulo: 'Las 4 modalidades de pensión',
    icono: Icons.swap_horiz_rounded,
    resumen: 'Las distintas formas en que puedes recibir tu pensión.',
    contenido: [
      'Cuando te pensionas, puedes elegir entre 4 modalidades distintas '
          'de recibir tu dinero. Cada una tiene ventajas diferentes según '
          'tu situación.',
      'Retiro Programado: tú mantienes el ahorro en tu AFP y retiras un '
          'monto mensual que se recalcula cada año.',
      'Renta Vitalicia Inmediata: traspasas tu ahorro a una compañía de '
          'seguros, que te paga un monto fijo mensual de por vida.',
      'Renta Temporal con Renta Vitalicia Diferida: combina un pago '
          'temporal desde tu AFP con una renta vitalicia que empieza '
          'más adelante.',
      'Renta Vitalicia Inmediata con Retiro Programado: combina ambas, '
          'una parte fija de por vida y otra parte variable desde tu AFP.',
      'Puedes explorar cada una con más detalle en el Simulador.',
    ],
    glosario: const [
      GlossaryTerm('Renta vitalicia',
          'Un pago mensual fijo que te acompaña de por vida, entregado '
              'por una compañía de seguros.'),
      GlossaryTerm('Retiro programado',
          'Una modalidad en la que mantienes tu ahorro en la AFP y '
              'retiras un monto mensual, que se ajusta cada año.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerEvaluacion,
      Segmento.hombreEvaluacion,
      Segmento.mujerRevision,
    ],
  ),
  Topic(
    id: 'beneficios_adicionales',
    titulo: 'Beneficios adicionales: PGU, Bono por Hijo y más',
    icono: Icons.volunteer_activism_outlined,
    resumen: 'Ayudas del Estado que pueden sumarse a tu pensión.',
    contenido: [
      'Además de tu ahorro en la AFP, existen beneficios del Estado que '
          'pueden aumentar tu pensión final.',
      'La Pensión Garantizada Universal (PGU) es un monto mensual que '
          'reciben las personas mayores que cumplen los requisitos, '
          'independiente de lo que hayan ahorrado.',
      'El Bono por Hijo es un aporte adicional para las mujeres, por '
          'cada hijo/a nacido/a vivo/a o adoptado/a.',
      'Existen otros beneficios (como el Aporte Previsional Solidario en '
          'casos antiguos, o beneficios para personas con menor ahorro) '
          'que tu AFP puede revisar contigo caso a caso.',
    ],
    notaPorSegmento: const {
      Segmento.mujerRevision:
          'Si estás en trámite de tu pensión, pregunta explícitamente en '
              'tu AFP por el Bono por Hijo: a veces no se aplica '
              'automáticamente y hay que solicitarlo.',
    },
    glosario: const [
      GlossaryTerm('Bono por Hijo',
          'Un aporte adicional al ahorro previsional de las mujeres, por '
              'cada hijo/a nacido/a vivo/a o adoptado/a.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerRevision,
      Segmento.hombreEvaluacion,
    ],
  ),
  Topic(
    id: 'documentos_tramites',
    titulo: 'Documentos y trámites para jubilar',
    icono: Icons.description_outlined,
    resumen: 'Qué necesitas y en qué orden hacer el trámite.',
    contenido: [
      'El trámite de pensión se hace directamente con tu AFP, de forma '
          'presencial, por teléfono o a través de su sitio web.',
      'Lo primero es solicitar un Certificado de Saldo, que muestra '
          'cuánto llevas ahorrado hasta ese momento.',
      'Luego puedes pedir ofertas de pensión en distintas modalidades, '
          'para comparar antes de decidir.',
      'Una vez que elijas una modalidad, firmas la solicitud y tu AFP (o '
          'la compañía de seguros, según la modalidad) comienza a pagar '
          'tu pensión.',
    ],
    glosario: const [
      GlossaryTerm('Certificado de Saldo',
          'Un documento de tu AFP que muestra cuánto dinero tienes '
              'ahorrado para tu pensión hasta la fecha.'),
    ],
    segmentosRelevantes: [
      Segmento.mujerRevision,
      Segmento.hombreEvaluacion,
    ],
  ),
  Topic(
    id: 'preguntas_frecuentes',
    titulo: 'Preguntas frecuentes',
    icono: Icons.help_outline_rounded,
    resumen: 'Dudas comunes sobre el proceso de jubilación.',
    contenido: [
      '¿Puedo seguir trabajando después de jubilar? Sí, en la mayoría de '
          'los casos puedes seguir trabajando y recibiendo tu pensión al '
          'mismo tiempo.',
      '¿Puedo cambiar de modalidad después de elegir una? Depende de la '
          'modalidad: algunas se pueden cambiar más adelante y otras no, '
          'por eso es importante informarse antes de decidir.',
      '¿Qué pasa si mi ahorro es bajo? Puedes acceder a la PGU y otros '
          'beneficios del Estado que ayudan a complementar tu pensión.',
    ],
    segmentosRelevantes: const [],
  ),
];

/// Devuelve los temas ordenados dejando primero los más relevantes para
/// el segmento de la persona, sin ocultar el resto.
List<Topic> temasOrdenadosPorSegmento(Segmento segmento) {
  final relevantes =
      topicsJubilo.where((t) => t.segmentosRelevantes.contains(segmento));
  final otros =
      topicsJubilo.where((t) => !t.segmentosRelevantes.contains(segmento));
  return [...relevantes, ...otros];
}
