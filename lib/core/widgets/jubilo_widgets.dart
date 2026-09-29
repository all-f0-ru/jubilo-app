import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return ElevatedButton(onPressed: onPressed, child: Text(label));
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
    return OutlinedButton(onPressed: onPressed, child: Text(label));
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent, width: selected ? 0 : 2),
        ),
        alignment: Alignment.center,
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
