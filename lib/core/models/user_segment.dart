/// Modelo de segmentación de Jubilo: determina en qué etapa previsional
/// está la persona según su sexo y edad, para personalizar el contenido
/// del flujo "Aprender". Basado en la guía de contenido entregada por el
/// supervisor del proyecto.
///
/// Reglas de negocio (ajustar aquí si cambia la normativa):
/// - Edad legal de pensión: 60 años (mujeres), 65 años (hombres).
/// - 5 segmentos: mujer en preparación, mujer en evaluación,
///   mujer en revisión/trámite, hombre en preparación,
///   hombre en evaluación/trámite.
library;

enum Segmento {
  mujerPreparacion,
  mujerEvaluacion,
  mujerRevision,
  hombrePreparacion,
  hombreEvaluacion,
}

class UserSegmentInfo {
  final Segmento segmento;
  final String etapa;
  final int edadLegal;
  final String mensaje;
  final bool mostrarAvisoNoObligacion;

  const UserSegmentInfo({
    required this.segmento,
    required this.etapa,
    required this.edadLegal,
    required this.mensaje,
    required this.mostrarAvisoNoObligacion,
  });
}

/// Calcula el segmento de una persona a partir de su sexo ('Hombre' o
/// 'Mujer') y su edad en años.
UserSegmentInfo computeSegment({required String sexo, required int edad}) {
  final esMujer = sexo == 'Mujer';
  final edadLegal = esMujer ? 60 : 65;
  final yaCumplioEdadLegal = edad >= edadLegal;

  if (esMujer) {
    if (edad < 60) {
      return UserSegmentInfo(
        segmento: Segmento.mujerPreparacion,
        etapa: 'Preparación',
        edadLegal: edadLegal,
        mensaje:
            'Todavía estás antes de la edad legal de pensión (60 años). '
            'Es un buen momento para prepararte y conocer tu situación '
            'con calma.',
        mostrarAvisoNoObligacion: yaCumplioEdadLegal,
      );
    } else if (edad < 65) {
      return UserSegmentInfo(
        segmento: Segmento.mujerEvaluacion,
        etapa: 'Evaluación',
        edadLegal: edadLegal,
        mensaje:
            'Ya cumpliste la edad legal de pensión (60 años). Es momento '
            'de evaluar tus opciones y beneficios disponibles.',
        mostrarAvisoNoObligacion: yaCumplioEdadLegal,
      );
    } else {
      return UserSegmentInfo(
        segmento: Segmento.mujerRevision,
        etapa: 'Revisión y trámite',
        edadLegal: edadLegal,
        mensaje:
            'Es un buen momento para revisar tu pensión y los beneficios '
            'a los que podrías acceder, como la PGU.',
        mostrarAvisoNoObligacion: yaCumplioEdadLegal,
      );
    }
  } else {
    if (edad < 65) {
      return UserSegmentInfo(
        segmento: Segmento.hombrePreparacion,
        etapa: 'Preparación',
        edadLegal: edadLegal,
        mensaje:
            'Todavía estás antes de la edad legal de pensión (65 años). '
            'Aprovecha este tiempo para prepararte y conocer tu '
            'situación.',
        mostrarAvisoNoObligacion: yaCumplioEdadLegal,
      );
    } else {
      return UserSegmentInfo(
        segmento: Segmento.hombreEvaluacion,
        etapa: 'Evaluación y trámite',
        edadLegal: edadLegal,
        mensaje:
            'Ya cumpliste la edad legal de pensión (65 años). Es momento '
            'de evaluar tus opciones y beneficios disponibles.',
        mostrarAvisoNoObligacion: yaCumplioEdadLegal,
      );
    }
  }
}

/// 3 recomendaciones orientativas según el segmento, mostradas en "Tu
/// situación" dentro de la pestaña Aprender.
List<String> recomendacionesPara(Segmento segmento) {
  switch (segmento) {
    case Segmento.mujerPreparacion:
    case Segmento.hombrePreparacion:
      return [
        'Revisa tu saldo y número de cotizaciones en la AFP.',
        'Aprovecha de informarte con calma, sin apuro.',
        'Conoce las 4 modalidades de pensión.',
      ];
    case Segmento.mujerEvaluacion:
    case Segmento.hombreEvaluacion:
      return [
        'Revisa tu saldo y número de cotizaciones en la AFP.',
        'Pide tu Certificado de Saldo.',
        'Conoce las 4 modalidades de pensión.',
      ];
    case Segmento.mujerRevision:
      return [
        'Pide ofertas de pensión en distintas modalidades para comparar.',
        'Pregunta por el Bono por Hijo y la PGU.',
        'Solicita tu Certificado de Saldo si todavía no lo tienes.',
      ];
  }
}
