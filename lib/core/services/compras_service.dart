import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/premium_provider.dart';
import 'correo_bienvenida_service.dart';
import 'nube_service.dart';

/// Resultado de intentar comprar Premium.
enum ResultadoCompra { exito, cancelada, pendiente, error }

/// Compra de Premium con Google Play Billing (pago único, producto "no
/// consumible").
///
/// Solo funciona en la app de Android instalada desde Google Play (o desde
/// una prueba interna). En la web y en el computador no hay compra real:
/// ahí Premium sigue siendo de demostración ([activa] es false).
///
/// IMPORTANTE: el producto debe existir en Google Play Console con el mismo
/// identificador que [productoId].
class ComprasService {
  ComprasService._();

  /// Identificador del producto en Google Play Console.
  static const String productoId = 'jubilo_premium';

  /// true solo en Android (no en la web).
  static bool get activa =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static PremiumProvider? _premium;
  static StreamSubscription<List<PurchaseDetails>>? _suscripcion;
  static ProductDetails? _producto;
  static Completer<ResultadoCompra>? _esperando;

  /// Precio tal como lo informa Google Play (por ejemplo "\$9.990"), o null
  /// si todavía no se pudo consultar.
  static String? get precioTexto => _producto?.price;

  /// Se llama una vez al iniciar la app.
  static Future<void> iniciar(PremiumProvider premium) async {
    if (!activa || _suscripcion != null) return;
    _premium = premium;
    try {
      _suscripcion = InAppPurchase.instance.purchaseStream
          .listen(_alRecibir, onError: (Object e) {
        debugPrint('Error en las compras: $e');
      });
      await cargarProducto();
      // Recupera una compra anterior (reinstalación, otro teléfono).
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('No se pudo iniciar Google Play Billing: $e');
    }
  }

  /// Consulta el precio y los datos del producto en Google Play.
  static Future<bool> cargarProducto() async {
    if (!activa) return false;
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return false;
      final resp = await iap.queryProductDetails({productoId});
      if (resp.productDetails.isEmpty) return false;
      _producto = resp.productDetails.first;
      return true;
    } catch (e) {
      debugPrint('No se pudo consultar el producto: $e');
      return false;
    }
  }

  /// Abre la ventana de pago de Google Play y espera el resultado.
  static Future<ResultadoCompra> comprar() async {
    if (!activa) return ResultadoCompra.error;
    if (_producto == null && !await cargarProducto()) {
      return ResultadoCompra.error;
    }
    _esperando = Completer<ResultadoCompra>();
    try {
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _producto!),
      );
      if (!ok) {
        _esperando = null;
        return ResultadoCompra.error;
      }
      return await _esperando!.future.timeout(const Duration(minutes: 5),
          onTimeout: () => ResultadoCompra.pendiente);
    } catch (e) {
      debugPrint('Error al comprar: $e');
      _esperando = null;
      return ResultadoCompra.error;
    }
  }

  /// "Ya compré Premium": vuelve a pedir a Google Play las compras hechas.
  static Future<void> restaurar() async {
    if (!activa) return;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('No se pudo restaurar: $e');
    }
  }

  static Future<void> _alRecibir(List<PurchaseDetails> compras) async {
    for (final c in compras) {
      if (c.productID != productoId) continue;
      switch (c.status) {
        case PurchaseStatus.pending:
          _terminar(ResultadoCompra.pendiente);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _premium?.activarPorCompra();
          await NubeService.marcarPremium(
            origen: 'google_play',
            productoId: c.productID,
            idCompra: c.purchaseID,
          );
          if (c.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(c);
          }
          // Solo en compras nuevas (no al restaurar una anterior).
          if (c.status == PurchaseStatus.purchased) {
            CorreoBienvenidaService.enviarSiCorresponde();
          }
          _terminar(ResultadoCompra.exito);
          break;
        case PurchaseStatus.canceled:
          _terminar(ResultadoCompra.cancelada);
          break;
        case PurchaseStatus.error:
          debugPrint('Compra con error: ${c.error}');
          if (c.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(c);
          }
          _terminar(ResultadoCompra.error);
          break;
      }
    }
  }

  static void _terminar(ResultadoCompra r) {
    final e = _esperando;
    if (e != null && !e.isCompleted) e.complete(r);
  }
}
