/// Cápsula informativa en video, mostrada en Inicio. Los links reales
/// todavía no fueron entregados — [videoUrl] queda en null hasta
/// entonces, y la tarjeta muestra un aviso "disponible pronto" al
/// tocarla en vez de intentar reproducir algo que no existe.
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
}

/// Mismo orden/temas que `topicsJubilo` en topic.dart, para que cada
/// cápsula corresponda 1 a 1 con un tema del flujo Aprender.
const List<CapsulaInformativa> capsulasInformativas = [
  CapsulaInformativa(
    id: 'que_es_pension',
    titulo: '¿Qué es la jubilación en Chile?',
    descripcion: 'Una explicación simple de cómo funciona el sistema de '
        'pensiones.',
    duracion: '3 min',
  ),
  CapsulaInformativa(
    id: 'modalidades_pension',
    titulo: 'Las 4 modalidades de pensión',
    descripcion: 'Conoce las formas de recibir tu pensión al jubilarte.',
    duracion: '4 min',
  ),
  CapsulaInformativa(
    id: 'ahorro_cotizaciones',
    titulo: 'Tu ahorro y las cotizaciones',
    descripcion: 'Cómo se forma el dinero que vas a recibir.',
    duracion: '3 min',
  ),
  CapsulaInformativa(
    id: 'edad_legal_requisitos',
    titulo: 'Edad legal y requisitos para jubilar',
    descripcion: 'Cuándo puedes empezar a pensionarte y qué necesitas.',
    duracion: '2 min',
  ),
  CapsulaInformativa(
    id: 'beneficios_adicionales',
    titulo: 'PGU, Bono por Hijo y más',
    descripcion: 'Ayudas del Estado que pueden sumarse a tu pensión.',
    duracion: '3 min',
  ),
  CapsulaInformativa(
    id: 'documentos_tramites',
    titulo: 'Documentos y trámites para jubilar',
    descripcion: 'Qué necesitas y en qué orden hacer el trámite.',
    duracion: '3 min',
  ),
  CapsulaInformativa(
    id: 'preguntas_frecuentes',
    titulo: 'Preguntas frecuentes',
    descripcion: 'Dudas comunes sobre el proceso de jubilación.',
    duracion: '2 min',
  ),
];
