import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/correo_bienvenida_service.dart';
import '../services/nube_service.dart';

/// Estado Premium de la persona (pago único que desbloquea: guardar
/// simulaciones, comparar modalidades y ver la gráfica de tendencia).
///
/// MODO DEMOSTRACIÓN: hoy [activarDemo] simula el pago y lo recuerda solo en
/// este dispositivo. Cuando haya pagos reales, el valor de [esPremium] debe
/// venir de una compra verificada (Google Play Billing en Android, o una
/// pasarela de pago en la web) y guardarse en la cuenta de la persona.
class PremiumProvider extends ChangeNotifier {
  static const String _clave = 'premium_activo';

  bool _esPremium = false;

  PremiumProvider() {
    _cargar();
  }

  bool get esPremium => _esPremium;

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _esPremium = prefs.getBool(_clave) ?? false;
      NubeService.fijarGuardado(_esPremium);
      notifyListeners();
    } catch (_) {
      // Sin almacenamiento disponible: se queda en no premium.
    }
  }

  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clave, _esPremium);
    } catch (_) {}
  }

  /// Simula el pago único. No cobra nada.
  Future<void> activarDemo() async {
    _esPremium = true;
    NubeService.fijarGuardado(true);
    notifyListeners();
    await _guardar();
  }

  /// Se llama cuando Google Play confirma una compra (o la restaura).
  Future<void> activarPorCompra() async {
    if (_esPremium) return;
    _esPremium = true;
    NubeService.fijarGuardado(true);
    notifyListeners();
    await _guardar();
  }

  /// Vuelve a la versión gratuita (sirve para probar el flujo de nuevo).
  Future<void> desactivar() async {
    _esPremium = false;
    NubeService.fijarGuardado(false);
    CorreoBienvenidaService.reiniciar();
    notifyListeners();
    await _guardar();
  }
}
