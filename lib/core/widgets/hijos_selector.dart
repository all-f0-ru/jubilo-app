import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pension_engine/modalidades_mixtas.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Permite indicar cuántos hijos/as tiene la persona y qué edad tiene cada
/// uno. Solo cuentan los que tienen derecho a pensión de sobrevivencia
/// (hasta 23 años). La lista se entrega por [onChanged].
class HijosSelector extends StatelessWidget {
  final List<int> edades;
  final ValueChanged<List<int>> onChanged;
  final double scale;
  final bool altoContraste;

  const HijosSelector({
    super.key,
    required this.edades,
    required this.onChanged,
    required this.scale,
    required this.altoContraste,
  });

  Color get _accent => altoContraste ? Colors.black : AppColors.teal;
  Color? get _texto => altoContraste ? Colors.black : null;

  Widget _boton(IconData icono, String etiqueta, VoidCallback? onTap,
      {double tamano = 44}) {
    final activo = onTap != null;
    return Semantics(
      button: true,
      label: etiqueta,
      enabled: activo,
      child: Material(
        color: activo ? _accent : AppColors.creamDeep,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: activo
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: SizedBox(
            width: tamano * scale.clamp(1.0, 1.3),
            height: tamano * scale.clamp(1.0, 1.3),
            child: Icon(icono,
                color: activo ? Colors.white : Colors.black38,
                size: 24 * scale.clamp(1.0, 1.3)),
          ),
        ),
      ),
    );
  }

  /// Cómo queda el derecho a pensión según la edad del hijo/a.
  String _situacion(int edad) =>
      edad <= 17 ? 'Menor de edad' : 'Se supone que estudia';

  @override
  Widget build(BuildContext context) {
    final fondo =
        altoContraste ? Colors.white : AppColors.teal.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: altoContraste ? Colors.black : AppColors.creamDeep,
            width: altoContraste ? 2 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Cantidad de hijos ----
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.family_restroom_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hijos/as con derecho a pensión',
                        style: AppTextStyles.small(scale, color: _texto)
                            .copyWith(fontWeight: FontWeight.w800)),
                    Text('Menores de 24 años',
                        style: AppTextStyles.small(scale * 0.9,
                            color: altoContraste ? Colors.black54 : null)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _boton(
                  Icons.remove_rounded,
                  'Quitar un hijo',
                  edades.isEmpty
                      ? null
                      : () => onChanged([...edades]..removeLast())),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Semantics(
                  label: edades.isEmpty
                      ? 'Ningún hijo'
                      : '${edades.length} hijos',
                  child: Text(
                    '${edades.length}',
                    style: AppTextStyles.heading(scale * 1.5, color: _texto),
                  ),
                ),
              ),
              _boton(
                  Icons.add_rounded,
                  'Agregar un hijo',
                  edades.length >= maximoHijos
                      ? null
                      : () => onChanged([...edades, 10])),
            ],
          ),
          if (edades.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Toca + para agregar a un hijo/a.',
                  style: AppTextStyles.small(scale,
                      color: altoContraste ? Colors.black54 : null)),
            ),
          ],

          // ---- Edad de cada hijo ----
          for (var i = 0; i < edades.length; i++) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: altoContraste ? Colors.black : AppColors.creamDeep),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hijo/a ${i + 1}',
                            style: AppTextStyles.small(scale, color: _texto)
                                .copyWith(fontWeight: FontWeight.w800)),
                        Text(_situacion(edades[i]),
                            style: AppTextStyles.small(scale * 0.9,
                                color:
                                    altoContraste ? Colors.black54 : null)),
                      ],
                    ),
                  ),
                  _boton(
                      Icons.remove_rounded,
                      'Bajar la edad del hijo ${i + 1}',
                      edades[i] <= 0
                          ? null
                          : () {
                              final n = [...edades];
                              n[i] = edades[i] - 1;
                              onChanged(n);
                            },
                      tamano: 38),
                  SizedBox(
                    width: 64 * scale.clamp(1.0, 1.3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${edades[i]}',
                            style: AppTextStyles.heading(scale,
                                color: _texto)),
                        Text('años',
                            style: AppTextStyles.small(scale * 0.85,
                                color:
                                    altoContraste ? Colors.black54 : null)),
                      ],
                    ),
                  ),
                  _boton(
                      Icons.add_rounded,
                      'Subir la edad del hijo ${i + 1}',
                      edades[i] >= edadMaximaHijo
                          ? null
                          : () {
                              final n = [...edades];
                              n[i] = edades[i] + 1;
                              onChanged(n);
                            },
                      tamano: 38),
                ],
              ),
            ),
          ],

          // ---- Explicación ----
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 20 * scale.clamp(1.0, 1.3),
                  color: altoContraste ? Colors.black : AppColors.tealDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Si tú fallecieras, tus hijos/as recibirían una pensión '
                  'hasta los 23 años (se supone que estudian desde los 18). '
                  'Cada uno recibe el 15% de tu pensión y el 50% se reparte '
                  'entre ellos (D.L. 3.500, art. 58). Es una aproximación '
                  'referencial.',
                  style: AppTextStyles.small(scale,
                      color: altoContraste ? Colors.black54 : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
