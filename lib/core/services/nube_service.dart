import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Conexión con Firebase: acceso anónimo y base de datos Firestore.
///
/// Estructura en Firestore (protegida por reglas: cada persona solo ve lo
/// suyo):
///   usuarios/{uid}                  -> encuesta, datos de las calculadoras,
///                                      cliente (nombre, teléfono, correo)
///   usuarios/{uid}/simulaciones/{id}-> cada simulación guardada
///
/// Todo es "a prueba de fallas": si no hay internet o Firebase no está
/// disponible, la app sigue funcionando con los datos del dispositivo.
class NubeService {
  static const Duration _espera = Duration(seconds: 8);

  static String? _uid;

  // -------- Guardado en la nube: SOLO si la persona opta por Premium --------
  //
  // Mientras la persona no se registre para Premium, nada de lo que escribe
  // (encuesta, saldo, simulaciones) sale de su dispositivo.
  static bool _guardadoHabilitado = false;
  static bool get guardadoHabilitado => _guardadoHabilitado;
  static final List<Future<void> Function()> _alHabilitar = [];

  /// Las pantallas/proveedores que tienen datos locales piden que se les avise
  /// cuando se habilite el guardado, para subir lo que ya tenían.
  static void alHabilitarGuardado(Future<void> Function() subir) {
    _alHabilitar.add(subir);
    // Si Premium ya estaba activo cuando se creó el proveedor, sube ahora.
    if (_guardadoHabilitado) subir();
  }

  /// La persona optó por Premium: desde ahora sus datos se guardan en la
  /// nube y se sube lo que ya tenía en el dispositivo.
  static Future<void> habilitarGuardado() async {
    if (_guardadoHabilitado) return;
    _guardadoHabilitado = true;
    for (final subir in List.of(_alHabilitar)) {
      try {
        await subir();
      } catch (e) {
        debugPrint('No se pudo subir datos locales: $e');
      }
    }
  }

  /// Se usa al abrir la app (Premium ya activo) o al desactivar Premium.
  static void fijarGuardado(bool activo) {
    if (activo) {
      habilitarGuardado();
    } else {
      _guardadoHabilitado = false;
    }
  }

  /// true cuando hay conexión con Firebase y la persona ya tiene su
  /// identificador anónimo.
  static bool get disponible => _uid != null;
  static String? get uid => _uid;

  /// Se llama una vez al abrir la app. Nunca lanza errores.
  static Future<void> iniciar() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(_espera);
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously().timeout(_espera);
      }
      _uid = auth.currentUser?.uid;
    } catch (e) {
      debugPrint('Firebase no disponible: $e');
      _uid = null;
    }
  }

  static DocumentReference<Map<String, dynamic>>? get _usuario {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('usuarios').doc(uid);
  }

  // ---------------- Escrituras que no bloquean la app ----------------

  static Future<void> _fusionar(Map<String, dynamic> datos) async {
    final doc = _usuario;
    if (doc == null) return;
    try {
      await doc
          .set({...datos, 'actualizado': FieldValue.serverTimestamp()},
              SetOptions(merge: true))
          .timeout(_espera);
    } catch (e) {
      debugPrint('No se pudo guardar en la nube: $e');
    }
  }

  static Future<void> guardarEncuesta(
      Map<String, dynamic> respuestas, DateTime fecha) async {
    if (!_guardadoHabilitado) return;
    return _fusionar({
      'encuesta': respuestas,
      'encuestaFecha': fecha.toIso8601String(),
    });
  }

  static Future<void> guardarDatosCalculo(
      {int? saldoClp,
      int? edad,
      int? aniosCotizados,
      Map<String, dynamic>? extras}) async {
    if (!_guardadoHabilitado) return;
    return _fusionar({
      'calculo': {
        'saldoClp': ?saldoClp,
        'edad': ?edad,
        'aniosCotizados': ?aniosCotizados,
        if (extras != null && extras.isNotEmpty) 'extras': extras,
      },
    });
  }

  static Future<void> guardarSimulacion(Map<String, dynamic> simulacion) async {
    final doc = _usuario;
    if (doc == null || !_guardadoHabilitado) return;
    try {
      await doc
          .collection('simulaciones')
          .doc(simulacion['id'] as String)
          .set({...simulacion, 'guardada': FieldValue.serverTimestamp()})
          .timeout(_espera);
    } catch (e) {
      debugPrint('No se pudo guardar la simulación en la nube: $e');
    }
  }

  static Future<void> guardarComparativa(Map<String, dynamic> comparativa) async {
    final doc = _usuario;
    if (doc == null || !_guardadoHabilitado) return;
    try {
      await doc
          .collection('comparativas')
          .doc(comparativa['id'] as String)
          .set({...comparativa, 'guardada': FieldValue.serverTimestamp()})
          .timeout(_espera);
    } catch (e) {
      debugPrint('No se pudo guardar la comparativa en la nube: $e');
    }
  }

  static Future<void> borrarComparativa(String id) async {
    final doc = _usuario;
    if (doc == null || !_guardadoHabilitado) return;
    try {
      await doc.collection('comparativas').doc(id).delete().timeout(_espera);
    } catch (e) {
      debugPrint('No se pudo borrar la comparativa en la nube: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> leerComparativas() async {
    final doc = _usuario;
    if (doc == null) return [];
    try {
      final snap = await doc.collection('comparativas').get().timeout(_espera);
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('No se pudieron leer las comparativas de la nube: $e');
      return [];
    }
  }

  static Future<void> borrarSimulacion(String id) async {
    final doc = _usuario;
    if (doc == null || !_guardadoHabilitado) return;
    try {
      await doc.collection('simulaciones').doc(id).delete().timeout(_espera);
    } catch (e) {
      debugPrint('No se pudo borrar la simulación en la nube: $e');
    }
  }

  // ---------------- Registro del cliente (sí avisa si falla) ----------------

  /// Guarda nombre, teléfono y correo de quien compra Premium. A diferencia
  /// de lo demás, SÍ lanza un error si no se pudo guardar, para no activar
  /// Premium sin tener el registro.
  static Future<void> registrarCliente(Map<String, dynamic> cliente) async {
    final doc = _usuario;
    if (doc == null) return;
    await doc.set({
      'cliente': cliente,
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(_espera);
    // La persona optó por Premium: desde aquí se guardan también sus datos.
    await habilitarGuardado();
  }

  /// Anota en la cuenta que la persona tiene Premium. [origen] es 'demo'
  /// (sin cobro) o 'google_play' (compra real).
  static Future<void> marcarPremium({
    required String origen,
    String? productoId,
    String? idCompra,
  }) {
    return _fusionar({
      'premium': true,
      'premiumFecha': FieldValue.serverTimestamp(),
      'premiumOrigen': origen,
      'compra': {
        'productoId': ?productoId,
        'idCompra': ?idCompra,
      },
    });
  }

  // ---------------- Lecturas ----------------

  /// Datos del documento de la persona (o null si no hay).
  static Future<Map<String, dynamic>?> leerUsuario() async {
    final doc = _usuario;
    if (doc == null) return null;
    try {
      final snap = await doc.get().timeout(_espera);
      return snap.data();
    } catch (e) {
      debugPrint('No se pudo leer de la nube: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> leerSimulaciones() async {
    final doc = _usuario;
    if (doc == null) return [];
    try {
      final snap = await doc.collection('simulaciones').get().timeout(_espera);
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('No se pudieron leer las simulaciones de la nube: $e');
      return [];
    }
  }
}
