/// Cápsula informativa en video, mostrada en Inicio. Si [videoUrl] es null,
/// la tarjeta muestra un aviso "disponible pronto" al tocarla.
class CapsulaInformativa {
  final String id;
  final String titulo;
  final String descripcion;
  final String duracion;
  final String? videoUrl;

  const CapsulaInformativa({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.duracion,
    this.videoUrl,
  });

  /// Identificador del video de YouTube, sacado del link (acepta los
  /// formatos watch?v=ID, youtu.be/ID y /shorts/ID).
  String? get _idYoutube {
    final url = videoUrl;
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final partes = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (partes.isEmpty) return null;
    if (uri.host.contains('youtu.be')) return partes.first;
    if (partes.length >= 2 && partes.first == 'shorts') return partes[1];
    return null;
  }

  /// Carátula del video (miniatura que publica YouTube). Null si no hay
  /// video o no se pudo leer su identificador.
  String? get miniaturaUrl {
    final id = _idYoutube;
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
  }
}

/// Cápsulas con video, en el mismo orden que `topicsJubilo` en topic.dart.
/// "Preguntas frecuentes" no tiene cápsula porque no hay un video para ella.
const List<CapsulaInformativa> capsulasInformativas = [
  CapsulaInformativa(
    id: 'que_es_pension',
    titulo: '¿Qué es la jubilación en Chile?',
    descripcion: 'Una explicación simple de cómo funciona el sistema de '
        'pensiones.',
    duracion: 'Video',
    // PAUTA (Chile), julio 2021: "¿Sabes cómo funciona el sistema de
    // pensiones en Chile?". Verificado que es de Chile. Ojo: es anterior a la
    // reforma de pensiones de 2025; validar si sigue sirviendo.
    videoUrl: 'https://www.youtube.com/watch?v=jMjP-ANJa2I',
  ),
  CapsulaInformativa(
    id: 'modalidades_pension',
    titulo: 'Las 4 modalidades de pensión',
    descripcion: 'Conoce las formas de recibir tu pensión al jubilarte.',
    duracion: 'Video',
    // MetLife Chile: "Diferencias entre el Retiro Programado y la Renta
    // Vitalicia". Validar duración y contenido antes de entregar.
    videoUrl: 'https://www.youtube.com/watch?v=rcHvCkAG6TY',
  ),
  CapsulaInformativa(
    id: 'ahorro_cotizaciones',
    titulo: 'Tu ahorro y las cotizaciones',
    descripcion: 'Cómo se forma el dinero que vas a recibir.',
    duracion: 'Video',
    // Sala de Prensa (abril 2026): "Aprende a simular tu pensión: ¿Cuánto
    // recibirás cuando seas jubilado?". Muestra la herramienta de la
    // Superintendencia de Pensiones; habla de ahorro obligatorio y voluntario.
    // No confirmé duración. Validar que calce con la cápsula.
    videoUrl: 'https://www.youtube.com/watch?v=gHrVnmIfiWY',
  ),
  CapsulaInformativa(
    id: 'edad_legal_requisitos',
    titulo: 'Edad legal y requisitos para jubilar',
    descripcion: 'Cuándo puedes empezar a pensionarte y qué necesitas.',
    duracion: 'Video corto',
    // VALIDAR: short "¿Jubilación anticipada en Chile? Conoce los requisitos
    // clave". Habla de jubilación anticipada, no de la edad legal.
    videoUrl: 'https://www.youtube.com/shorts/J650-KpwL84',
  ),
  CapsulaInformativa(
    id: 'beneficios_adicionales',
    titulo: 'PGU, Bono por Hijo y más',
    descripcion: 'Ayudas del Estado que pueden sumarse a tu pensión.',
    duracion: 'Video corto',
    // ChileAtiende (oficial), short sobre la PGU.
    videoUrl: 'https://www.youtube.com/watch?v=gDHb_8pbTWU',
  ),
  CapsulaInformativa(
    id: 'documentos_tramites',
    titulo: 'Documentos y trámites para jubilar',
    descripcion: 'Qué necesitas y en qué orden hacer el trámite.',
    duracion: 'Video',
    // AFP Capital (abril 2026): "Certificado de Saldos: Qué es y cómo
    // descargarlo". Es un canal de una AFP (no oficial del Estado), pero es
    // chileno y explica el primer documento del trámite. No confirmé duración.
    videoUrl: 'https://www.youtube.com/watch?v=HaKawNT0ZoM',
  ),
];
