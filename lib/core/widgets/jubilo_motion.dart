import 'dart:async';
import 'package:flutter/material.dart';

/// Utilidades de movimiento de Jubilo. Reglas de diseño:
/// - Todo movimiento dura menos de 400 ms.
/// - Si la persona tiene activado "reducir animaciones" en su
///   dispositivo, no se anima nada (ver [reduceMotion]).

/// true si el dispositivo pidió reducir animaciones.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Transición entre pantallas: desvanecido + leve deslizamiento lateral.
/// Se usa igual que MaterialPageRoute: `JubiloPageRoute(builder: ...)`.
class JubiloPageRoute<T> extends PageRouteBuilder<T> {
  JubiloPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (reduceMotion(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Entrada escalonada: el hijo aparece desvaneciéndose y subiendo un
/// poco, con un retraso según su [index] (máx. 8 posiciones, para que
/// listas largas no tarden en mostrarse).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 60 * widget.index.clamp(0, 8));
    _timer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// Efecto de presión: el hijo se encoge un poco mientras se toca.
/// Usa un Listener, así no le quita los toques al InkWell de adentro.
class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PressableScale({super.key, required this.child, this.enabled = true});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (!widget.enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
