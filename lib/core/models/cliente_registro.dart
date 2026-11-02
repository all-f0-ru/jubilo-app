/// Datos que la persona entrega antes de pagar Premium.
/// Sirven para tener el registro del cliente (hoy local, luego Firebase).
class ClienteRegistro {
  final String nombre;
  final String telefono;
  final String correo;
  final DateTime fecha;

  const ClienteRegistro({
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'telefono': telefono,
        'correo': correo,
        'fecha': fecha.toIso8601String(),
      };

  factory ClienteRegistro.fromJson(Map<String, dynamic> j) => ClienteRegistro(
        nombre: j['nombre'] as String? ?? '',
        telefono: j['telefono'] as String? ?? '',
        correo: j['correo'] as String? ?? '',
        fecha: DateTime.tryParse(j['fecha'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Validaciones simples de los campos del registro.
String? validarNombre(String? v) {
  final t = (v ?? '').trim();
  if (t.length < 3) return 'Escribe tu nombre completo';
  return null;
}

String? validarTelefono(String? v) {
  final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  final ok = d.length == 9 || (d.length == 11 && d.startsWith('56'));
  if (!ok) return 'Escribe un número válido, por ejemplo 9 1234 5678';
  return null;
}

String? validarCorreo(String? v) {
  final t = (v ?? '').trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
    return 'Escribe un correo válido, por ejemplo nombre@correo.cl';
  }
  return null;
}
