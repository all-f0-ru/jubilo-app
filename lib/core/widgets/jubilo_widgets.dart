import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'jubilo_motion.dart';

/// Envuelve un callback para que además dispare una vibración suave.
/// Devuelve null si [callback] es null (el botón queda deshabilitado).
VoidCallback? _conVibracion(VoidCallback? callback) {
  if (callback == null) return null;
  return () {
    HapticFeedback.selectionClick();
    callback();
  };
}

/// Librería de componentes reutilizables de Jubilo. Todos respetan el
/// tamaño mínimo de toque (48px de alto) y usan los estilos del sistema
/// de diseño en vez de valores sueltos.

/// Botón primario grande (fondo teal). Ya viene estilado por el tema,
/// pero se envuelve para tener un solo lugar donde ajustar su
/// comportamiento en toda la app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Si es true, [icon] se dibuja después del texto (ej. "Siguiente →")
  /// en vez de antes. Coincide con el patrón usado en varios botones del
  /// diseño de referencia.
  final bool trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = _conVibracion(onPressed);
    if (icon != null && trailingIcon) {
      return ElevatedButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      );
    }
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return ElevatedButton(onPressed: onTap, child: Text(label));
  }
}

/// Botón secundario grande (borde coral).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: _conVibracion(onPressed), child: Text(label));
  }
}

/// Tarjeta grande seleccionable, usada en las preguntas del simulador
/// (edad, sexo, estado civil, hijos) en vez de radio buttons pequeños.
class OptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highContrast;

  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highContrast ? Colors.black : AppColors.teal;
    return PressableScale(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: selected ? 0 : 2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El check aparece al seleccionar: así la selección no
              // depende solo del color.
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: selected
                    ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_rounded,
                            color: Colors.white, size: 20),
                      )
                    : const SizedBox.shrink(),
              ),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de progreso simple para el onboarding ("pantalla 1 de 2").
class ProgressDots extends StatelessWidget {
  final int total;
  final int activeIndex; // 0-based
  final bool highContrast;

  const ProgressDots({
    super.key,
    required this.total,
    required this.activeIndex,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highContrast ? Colors.black : AppColors.teal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

enum BannerVariant { info, warning }

/// Banner/aviso reutilizable. Variante "info" para avisos generales
/// (ej. disclaimer del simulador) y "warning" para advertencias
/// previsionales (ej. "cumplir la edad legal no te obliga a jubilarte").
class InfoBanner extends StatelessWidget {
  final String text;
  final BannerVariant variant;
  final double fontScale;

  const InfoBanner({
    super.key,
    required this.text,
    this.variant = BannerVariant.info,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = variant == BannerVariant.warning;
    final bg = isWarning ? const Color(0xFFFBEAD9) : AppColors.creamDeep;
    final fg = isWarning ? AppColors.coralDeep : AppColors.inkSoft;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isWarning ? Icons.info_outline : Icons.lightbulb_outline,
              color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.small(fontScale, color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Insignia circular de ícono con fondo de color suave. Da más calidez
/// visual que un ícono solo, y se usa en tarjetas de tema, pasos y
/// modalidades de pensión.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Tarjeta estándar (fondo blanco, esquinas redondeadas, sombra suave)
/// usada en listas de temas, modalidades y resultados. Reemplaza los
/// `Container` con solo borde por una versión con más profundidad.
class JubiloCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const JubiloCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.creamDeep,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressableScale(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

/// Chip pequeño reutilizable (ej. "Relevante para tu etapa", filtros).
class AppChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AppChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Sección que se abre y se cierra con un toque. Deja la pantalla limpia:
/// el detalle aparece solo cuando la persona lo pide.
class Plegable extends StatefulWidget {
  final String titulo;
  final IconData? icono;
  final Color? color;
  final Widget child;
  final bool abiertoInicial;
  final bool highContrast;
  final double fontScale;

  /// Texto corto a la derecha del título (ej. la cantidad de ítems).
  final String? detalle;

  const Plegable({
    super.key,
    required this.titulo,
    required this.child,
    this.icono,
    this.color,
    this.abiertoInicial = false,
    this.highContrast = false,
    this.fontScale = 1.0,
    this.detalle,
  });

  @override
  State<Plegable> createState() => _PlegableState();
}

class _PlegableState extends State<Plegable> {
  late bool _abierto = widget.abiertoInicial;

  @override
  Widget build(BuildContext context) {
    final hc = widget.highContrast;
    final color = hc ? Colors.black : (widget.color ?? AppColors.teal);
    final duracion = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return JubiloCard(
      padding: EdgeInsets.zero,
      borderColor: hc ? Colors.black : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _abierto = !_abierto);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  if (widget.icono != null) ...[
                    IconBadge(icon: widget.icono!, color: color, size: 40),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: AppTextStyles.heading(widget.fontScale * 0.74,
                          color: hc ? Colors.black : null),
                    ),
                  ),
                  if (widget.detalle != null) ...[
                    AppChip(label: widget.detalle!, color: color),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: _abierto ? 0.5 : 0,
                    duration: duracion,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: hc ? Colors.black : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: duracion,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _abierto
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Selector numérico con botones − y + grandes, para no obligar a usar el
/// teclado (ej. la edad).
class StepperNumero extends StatelessWidget {
  final int valor;
  final int minimo;
  final int maximo;
  final String sufijo;
  final ValueChanged<int> onChanged;
  final bool highContrast;
  final double fontScale;

  const StepperNumero({
    super.key,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.onChanged,
    this.sufijo = '',
    this.highContrast = false,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highContrast ? Colors.black : AppColors.teal;
    final texto = sufijo.isEmpty ? '$valor' : '$valor $sufijo';

    Widget boton(IconData icono, String etiqueta, bool activo, int delta) {
      return Semantics(
        button: true,
        enabled: activo,
        label: etiqueta,
        child: PressableScale(
          enabled: activo,
          child: Material(
            color: activo ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: activo
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(valor + delta);
                    }
                  : null,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(icono, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        boton(Icons.remove_rounded, 'Restar uno', valor > minimo, -1),
        Expanded(
          child: Center(
            child: Text(
              texto,
              style: AppTextStyles.heading(fontScale,
                  color: highContrast ? Colors.black : null),
            ),
          ),
        ),
        boton(Icons.add_rounded, 'Sumar uno', valor < maximo, 1),
      ],
    );
  }
}
