import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pension_engine/modalidades_mixtas.dart';
import '../pension_engine/pension_config.dart';
import 'nube_service.dart';

/// Mantiene al día las tasas, la UF, la PGU y la BAC sin tener que publicar
/// la app de nuevo.
///
/// Orden de prioridad para cada dato (si uno falla se usa el siguiente):
///  1. UF: servicio gratuito mindicador.cl (valor de hoy).
///  2. Tasas, PGU y BAC: documento `configuracion/parametros` en Firestore.
///  3. Última copia guardada en este dispositivo.
///  4. Valores que vienen escritos en el código.
class ParametrosService {
  ParametrosService._();

  static const String _kCache = 'parametros_cache';
  static bool _iniciado = false;

  /// Aplica la copia guardada (rápido, sin internet) y luego intenta
  /// actualizar en segundo plano. No hace esperar el inicio de la app.
  static Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;
    await _aplicarCopiaGuardada();
    // Sin await: la app abre de inmediato.
    actualizar();
  }

  static Future<void> _aplicarCopiaGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCache);
      if (raw == null) return;
      _aplicarMapa(jsonDecode(raw) as Map<String, dynamic>, origen: 'guardado');
    } catch (e) {
      debugPrint('Sin copia de parámetros: $e');
    }
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  static void _aplicarMapa(Map<String, dynamic> m, {required String origen}) {
    final fecha = DateTime.tryParse('${m['valorUfFecha'] ?? ''}');
    ParametrosVigentes.aplicar(
      tasaVejez: _num(m['tasaReferenciaVejez']),
      tasaRp: _num(m['tasaRetiroProgramado']),
      rentabilidad: _num(m['rentabilidadReal']),
      uf: _num(m['valorUf']),
      ufFecha: fecha,
      origenDeUf: origen,
    );
    if (m['tasaReferenciaVejez'] != null || m['tasaRetiroProgramado'] != null) {
      ParametrosVigentes.tasasActualizadas = true;
    }
    final base = parametrosPguBacActual;
    parametrosPguBacActual = ParametrosPguBac(
      pguMaxima: _positivo(_num(m['pguMaxima']), base.pguMaxima),
      pensionInferior:
          _positivo(_num(m['pguPensionInferior']), base.pensionInferior),
      pensionSuperior:
          _positivo(_num(m['pguPensionSuperior']), base.pensionSuperior),
      bacUfPorAnio: _positivo(_num(m['bacUfPorAnio']), base.bacUfPorAnio),
      bacTopeAnios: _positivo(_num(m['bacTopeAnios']), base.bacTopeAnios.toDouble())
          .round(),
    );
  }

  static double _positivo(double? nuevo, double actual) =>
      (nuevo != null && nuevo > 0) ? nuevo : actual;

  /// Busca valores nuevos. Nunca lanza errores: si algo falla, quedan los
  /// valores que ya había.
  static Future<void> actualizar() async {
    final guardar = <String, dynamic>{};

    // 1) Tasas, PGU, BAC (y UF de respaldo) desde Firestore.
    try {
      if (NubeService.disponible) {
        final snap = await FirebaseFirestore.instance
            .collection('configuracion')
            .doc('parametros')
            .get()
            .timeout(const Duration(seconds: 8));
        final datos = snap.data();
        if (datos != null) {
          final limpio = <String, dynamic>{
            for (final e in datos.entries)
              e.key: e.value is Timestamp
                  ? (e.value as Timestamp).toDate().toIso8601String()
                  : e.value,
          };
          _aplicarMapa(limpio, origen: 'firebase');
          guardar.addAll(limpio);
        }
      }
    } catch (e) {
      debugPrint('No se pudieron leer los parámetros de Firebase: $e');
    }

    // 2) UF del día (si responde, manda por sobre la de Firebase).
    try {
      final r = await http
          .get(Uri.parse('https://mindicador.cl/api/uf'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final serie = j['serie'] as List?;
        if (serie != null && serie.isNotEmpty) {
          final hoy = serie.first as Map<String, dynamic>;
          final valor = _num(hoy['valor']);
          final fecha = DateTime.tryParse('${hoy['fecha']}')?.toLocal();
          if (valor != null) {
            ParametrosVigentes.aplicar(
                uf: valor,
                ufFecha: fecha == null
                    ? null
                    : DateTime(fecha.year, fecha.month, fecha.day),
                origenDeUf: 'automatico');
            guardar['valorUf'] = valor;
            if (fecha != null) {
              guardar['valorUfFecha'] =
                  DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('No se pudo traer la UF automática: $e');
    }

    if (guardar.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final previo = prefs.getString(_kCache);
        final base = previo == null
            ? <String, dynamic>{}
            : jsonDecode(previo) as Map<String, dynamic>;
        base.addAll(guardar);
        await prefs.setString(_kCache, jsonEncode(base));
      } catch (_) {}
    }
  }

  /// Texto corto para mostrar en "Supuestos".
  static String descripcionUf() {
    switch (ParametrosVigentes.origenUf) {
      case 'automatico':
        return 'UF del día (actualizada automáticamente)';
      case 'firebase':
        return 'UF informada por Jubilo';
      case 'guardado':
        return 'Última UF guardada en este dispositivo';
      default:
        return 'UF de referencia incluida en la app';
    }
  }
}
