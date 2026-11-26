import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/comparativa_guardada.dart';
import '../../core/models/simulacion_guardada.dart';
import '../../core/models/simulador_models.dart';
import '../../core/providers/comparativas_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/respuestas_encuesta_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/simulaciones_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/premium_sheet.dart';
import 'comparar_modalidades_screen.dart';

String _puntos(String digitos) {
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

String _clp(num v) => '\$${_puntos(v.round().toString())}';

String _dos(int n) => n.toString().padLeft(2, '0');

String _fechaHora(DateTime d) =>
    '${_dos(d.day)}-${_dos(d.month)}-${d.year} ${_dos(d.hour)}:${_dos(d.minute)}';

String _fechaCorta(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

/// Color de cada modalidad (el mismo que en el resto de la app).
Color _colorModalidad(String modalidad, bool hc) {
  if (hc) {
    final i = SimulacionGuardada.todas.indexOf(modalidad);
    const grises = [
      Colors.black,
      Colors.black54,
      Colors.black38,
      Colors.black26
    ];
    return grises[i < 0 ? 0 : i];
  }
  final id = SimulacionGuardada.idInfo(modalidad);
  return modalidadesPension.firstWhere((m) => m.id == id).color;
}

/// Mis simulaciones (Premium): lista de las simulaciones guardadas, cada una
/// con su monto y hora, y una gráfica con la tendencia de la pensión
/// estimada. Sin Premium, ofrece desbloquearlo.
class MisSimulacionesScreen extends StatelessWidget {
  const MisSimulacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final premium = context.watch<PremiumProvider>().esPremium;
    final simulaciones = context.watch<SimulacionesProvider>();
    final lista = simulaciones.todas;
    final comparativas = context.watch<ComparativasProvider>().todas;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mis simulaciones',
            style: AppTextStyles.heading(0.85, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (!premium)
              _Bloqueado(scale: scale, hc: hc)
            else ...[
              _TarjetaComparar(
                scale: scale,
                hc: hc,
                onTap: () => Navigator.of(context).push(
                  JubiloPageRoute(
                    builder: (_) => CompararModalidadesScreen(
                        respuestas: context
                                .read<RespuestasEncuestaProvider>()
                                .respuestas ??
                            respuestasPorDefecto(settings)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (premium && lista.isEmpty && comparativas.isEmpty)
              _Vacio(scale: scale, hc: hc),
            if (premium && comparativas.isNotEmpty) ...[
              Text('Comparativas guardadas (${comparativas.length})',
                  style: AppTextStyles.heading(scale * 0.8,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 12),
              for (final c in comparativas.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TarjetaComparativa(
                      comparativa: c, scale: scale, hc: hc),
                ),
              const SizedBox(height: 12),
            ],
            if (premium && lista.isNotEmpty) ...[
              _TarjetaGrafica(simulaciones: lista, scale: scale, hc: hc),
              const SizedBox(height: 24),
              Text('Guardadas (${lista.length})',
                  style: AppTextStyles.heading(scale * 0.8,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 12),
              for (final s in lista.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TarjetaSimulacion(
                    simulacion: s,
                    scale: scale,
                    hc: hc,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaComparar extends StatelessWidget {
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _TarjetaComparar(
      {required this.scale, required this.hc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      borderColor: accent,
      borderWidth: 2,
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: Icons.compare_arrows_rounded, color: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Compara las modalidades con tu saldo',
                style: AppTextStyles.heading(scale * 0.75,
                    color: hc ? Colors.black : null)),
          ),
          Icon(Icons.arrow_forward_rounded, color: accent),
        ],
      ),
    );
  }
}

class _Bloqueado extends StatelessWidget {
  final double scale;
  final bool hc;

  const _Bloqueado({required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.lock_outline_rounded, color: accent, size: 48),
          const SizedBox(height: 14),
          Text('Esta sección es Premium',
              style: AppTextStyles.heading(scale * 0.85,
                  color: hc ? Colors.black : null)),
          const SizedBox(height: 8),
          Text(
            'Guarda cada simulación con su monto y hora, compara las '
            'modalidades con tu saldo y mira cómo cambia tu pensión en una '
            'gráfica.',
            style: AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => mostrarPremiumSheet(context),
              child: const Text('Ver Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final double scale;
  final bool hc;

  const _Vacio({required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      child: Row(
        children: [
          IconBadge(icon: Icons.bookmark_border_rounded, color: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Aún no guardas ninguna. Haz una simulación y toca '
              '"Guardar simulación".',
              style:
                  AppTextStyles.body(scale, color: hc ? Colors.black87 : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSimulacion extends StatelessWidget {
  final SimulacionGuardada simulacion;
  final double scale;
  final bool hc;

  const _TarjetaSimulacion({
    required this.simulacion,
    required this.scale,
    required this.hc,
  });

  Future<void> _confirmarBorrado(BuildContext context) async {
    final simulaciones = context.read<SimulacionesProvider>();
    final borrar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar esta simulación?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (borrar == true) {
      await simulaciones.eliminar(simulacion.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorModalidad(simulacion.modalidad, hc);
    final suave = hc ? Colors.black54 : null;

    return JubiloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(label: simulacion.nombreModalidad, color: color),
              const Spacer(),
              IconButton(
                tooltip: 'Borrar',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmarBorrado(context),
                icon: Icon(Icons.delete_outline_rounded,
                    color: hc ? Colors.black : AppColors.inkSoft),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_clp(simulacion.pensionMensualClp),
                style: AppTextStyles.display(scale * 0.85,
                    color: hc ? Colors.black : color)),
          ),
          Text(simulacion.bajada,
              style: AppTextStyles.small(scale, color: suave)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pildora(
                  icono: Icons.savings_outlined,
                  texto: 'Saldo ${_clp(simulacion.saldoClp)}',
                  scale: scale,
                  hc: hc),
              _Pildora(
                  icono: Icons.cake_outlined,
                  texto: '${simulacion.edad} años',
                  scale: scale,
                  hc: hc),
              if (simulacion.conConyuge)
                _Pildora(
                    icono: Icons.favorite_border_rounded,
                    texto: 'Con cónyuge',
                    scale: scale,
                    hc: hc),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 15, color: hc ? Colors.black54 : AppColors.inkSoft),
              const SizedBox(width: 6),
              Text(_fechaHora(simulacion.fecha),
                  style: AppTextStyles.small(scale * 0.9, color: suave)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dato corto con ícono, en forma de "píldora".
class _Pildora extends StatelessWidget {
  final IconData icono;
  final String texto;
  final double scale;
  final bool hc;

  const _Pildora({
    required this.icono,
    required this.texto,
    required this.scale,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hc ? Colors.white : AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hc ? Colors.black : AppColors.creamDeep),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono,
              size: 16, color: hc ? Colors.black : AppColors.tealDeep),
          const SizedBox(width: 6),
          Text(texto,
              style: AppTextStyles.small(scale * 0.95,
                  color: hc ? Colors.black : AppColors.ink)),
        ],
      ),
    );
  }
}

/// Resumen gráfico: la última simulación de cada modalidad en barras y, si
/// alguna se repitió, cómo cambió la pensión desde la primera.
class _TarjetaGrafica extends StatelessWidget {
  final List<SimulacionGuardada> simulaciones; // de la más antigua a la nueva
  final double scale;
  final bool hc;

  const _TarjetaGrafica({
    required this.simulaciones,
    required this.scale,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    final presentes = SimulacionGuardada.todas
        .where((m) => simulaciones.any((s) => s.modalidad == m))
        .toList();
    final colores = {for (final m in presentes) m: _colorModalidad(m, hc)};
    List<SimulacionGuardada> deModalidad(String m) =>
        simulaciones.where((s) => s.modalidad == m).toList();
    final ultimas = [for (final m in presentes) deModalidad(m).last];
    final maximo = ultimas.fold<double>(
        0, (v, s) => s.pensionMensualClp > v ? s.pensionMensualClp : v);
    final repetidas =
        presentes.where((m) => deModalidad(m).length > 1).toList();
    final suave = hc ? Colors.black54 : null;

    return JubiloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de tus simulaciones',
              style: AppTextStyles.heading(scale * 0.8,
                  color: hc ? Colors.black : null)),
          const SizedBox(height: 4),
          Text('Última simulación guardada de cada modalidad',
              style: AppTextStyles.small(scale, color: suave)),
          const SizedBox(height: 14),
          for (final s in ultimas) ...[
            Row(
              children: [
                Expanded(
                  child: Text(s.nombreModalidad,
                      style: AppTextStyles.small(scale,
                              color: hc ? Colors.black : null)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('${_clp(s.pensionMensualClp)} al mes',
                    style: AppTextStyles.small(scale,
                            color: hc ? Colors.black : null)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maximo <= 0
                    ? 0
                    : (s.pensionMensualClp / maximo).clamp(0.0, 1.0),
                minHeight: 12,
                color: colores[s.modalidad],
                backgroundColor: hc ? Colors.black12 : AppColors.creamDeep,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (repetidas.isEmpty)
            Text(
              'Cuando repitas una simulación, aquí verás cómo cambia tu '
              'pensión.',
              style: AppTextStyles.small(scale, color: suave),
            )
          else ...[
            const Divider(height: 24),
            Text('Cómo ha cambiado',
                style: AppTextStyles.body(scale,
                        color: hc ? Colors.black : null)
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final m in repetidas) ...[
              Builder(builder: (_) {
                final lista = deModalidad(m);
                final dif = lista.last.pensionMensualClp -
                    lista.first.pensionMensualClp;
                final sube = dif >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                          sube
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 20,
                          color: hc ? Colors.black : colores[m]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lista.first.nombreModalidad}: '
                          '${sube ? '+' : '−'}${_clp(dif.abs())} al mes '
                          'desde tu primera simulación',
                          style: AppTextStyles.small(scale,
                              color: hc ? Colors.black : null),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final m in repetidas)
                  _Leyenda(
                      texto: deModalidad(m).first.nombreModalidad,
                      color: colores[m]!),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _TendenciaPainter(
                  simulaciones: [
                    for (final s in simulaciones)
                      if (repetidas.contains(s.modalidad)) s
                  ],
                  colores: colores,
                  textoColor: hc ? Colors.black87 : AppColors.inkSoft,
                  rejillaColor: hc ? Colors.black26 : AppColors.creamDeep,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final String texto;
  final Color color;

  const _Leyenda({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// Dibuja la línea de tendencia: una serie por modalidad, con los puntos
/// repartidos en el orden en que se hicieron las simulaciones.
class _TendenciaPainter extends CustomPainter {
  final List<SimulacionGuardada> simulaciones;
  final Map<String, Color> colores;
  final Color textoColor;
  final Color rejillaColor;

  const _TendenciaPainter({
    required this.simulaciones,
    required this.colores,
    required this.textoColor,
    required this.rejillaColor,
  });

  void _texto(Canvas canvas, String texto, Offset origen, double ancho,
      TextAlign alineacion) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(fontSize: 11, color: textoColor),
      ),
      textAlign: alineacion,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: ancho, maxWidth: ancho);
    tp.paint(canvas, origen);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (simulaciones.isEmpty) return;

    const izq = 76.0;
    const der = 12.0;
    const arriba = 12.0;
    const abajo = 26.0;
    final ancho = size.width - izq - der;
    final alto = size.height - arriba - abajo;
    if (ancho <= 0 || alto <= 0) return;

    var minY =
        simulaciones.map((s) => s.pensionMensualClp).reduce(math.min);
    var maxY =
        simulaciones.map((s) => s.pensionMensualClp).reduce(math.max);
    if ((maxY - minY).abs() < 1) {
      minY = minY * 0.9;
      maxY = maxY * 1.1;
    } else {
      final margen = (maxY - minY) * 0.12;
      minY -= margen;
      maxY += margen;
    }
    if (minY < 0) minY = 0;
    if (maxY <= minY) maxY = minY + 1;

    double yDe(double v) => arriba + alto * (1 - (v - minY) / (maxY - minY));
    double xDe(int i) => simulaciones.length == 1
        ? izq + ancho / 2
        : izq + ancho * i / (simulaciones.length - 1);

    // Rejilla con 3 niveles de monto.
    final rejilla = Paint()
      ..color = rejillaColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = arriba + alto * i / 2;
      canvas.drawLine(Offset(izq, y), Offset(size.width - der, y), rejilla);
      final valor = maxY - (maxY - minY) * i / 2;
      _texto(canvas, _clp(valor), Offset(0, y - 7), izq - 6, TextAlign.right);
    }

    // Una línea por modalidad.
    for (final modalidad in SimulacionGuardada.todas) {
      final color = colores[modalidad] ?? Colors.black;
      final puntos = <Offset>[];
      for (var i = 0; i < simulaciones.length; i++) {
        if (simulaciones[i].modalidad == modalidad) {
          puntos.add(
              Offset(xDe(i), yDe(simulaciones[i].pensionMensualClp)));
        }
      }
      if (puntos.isEmpty) continue;

      if (puntos.length > 1) {
        final camino = Path()..moveTo(puntos.first.dx, puntos.first.dy);
        for (final p in puntos.skip(1)) {
          camino.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          camino,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round,
        );
      }
      for (final p in puntos) {
        canvas.drawCircle(p, 6, Paint()..color = Colors.white);
        canvas.drawCircle(p, 4.5, Paint()..color = color);
      }
    }

    // Fechas del primer y del último punto.
    final yFecha = size.height - abajo + 8;
    if (simulaciones.length == 1) {
      _texto(canvas, _fechaCorta(simulaciones.first.fecha),
          Offset(izq + ancho / 2 - 35, yFecha), 70, TextAlign.center);
    } else {
      _texto(canvas, _fechaCorta(simulaciones.first.fecha),
          Offset(izq, yFecha), 70, TextAlign.left);
      _texto(canvas, _fechaCorta(simulaciones.last.fecha),
          Offset(size.width - der - 70, yFecha), 70, TextAlign.right);
    }
  }

  @override
  bool shouldRepaint(covariant _TendenciaPainter old) => true;
}

/// Una comparativa guardada: los datos usados y lo que dio cada modalidad.
class _TarjetaComparativa extends StatelessWidget {
  final ComparativaGuardada comparativa;
  final double scale;
  final bool hc;

  const _TarjetaComparativa({
    required this.comparativa,
    required this.scale,
    required this.hc,
  });

  Future<void> _confirmarBorrado(BuildContext context) async {
    final provider = context.read<ComparativasProvider>();
    final borrar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar esta comparativa?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (borrar == true) await provider.eliminar(comparativa.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = comparativa;
    final mayor = c.mayor;
    final maximo = c.filas.fold<double>(
        0, (m, f) => f.montoClp > m ? f.montoClp : m);
    final accent = hc ? Colors.black : AppColors.teal;

    return JubiloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.compare_arrows_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo ${_clp(c.saldoClp)}',
                        style: AppTextStyles.body(scale,
                                color: hc ? Colors.black : null)
                            .copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      '${_fechaHora(c.fecha)} · ${c.edad} años · '
                      '${c.aniosCotizados} años cotizados',
                      style: AppTextStyles.small(scale,
                          color: hc ? Colors.black54 : null),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Borrar',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmarBorrado(context),
                icon: Icon(Icons.delete_outline_rounded,
                    color: hc ? Colors.black : AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final f in c.filas) ...[
            Row(
              children: [
                Expanded(
                  child: Text(f.nombre,
                      style: AppTextStyles.small(scale,
                              color: hc ? Colors.black : null)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                if (c.filas.length > 1 && identical(f, mayor)) ...[
                  Icon(Icons.star_rounded,
                      size: 16, color: hc ? Colors.black : AppColors.coral),
                  const SizedBox(width: 4),
                ],
                Text(_clp(f.montoClp),
                    style: AppTextStyles.small(scale,
                            color: hc ? Colors.black : null)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maximo <= 0 ? 0 : (f.montoClp / maximo).clamp(0.0, 1.0),
                minHeight: 12,
                color: _colorModalidad(f.modalidad, hc),
                backgroundColor: hc ? Colors.black12 : AppColors.creamDeep,
              ),
            ),
            if (f.pguClp > 0 || f.bacClp > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'Con PGU y BAC desde los 65: ${_clp(f.totalClp)}',
                  style: AppTextStyles.small(scale * 0.9,
                      color: hc ? Colors.black54 : null),
                ),
              ),
            const SizedBox(height: 10),
          ],
          if (mayor != null && c.filas.length > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hc ? Colors.white : AppColors.cream,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: hc ? Colors.black : AppColors.creamDeep),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 18, color: hc ? Colors.black : AppColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Mayor monto al mes: ${mayor.nombre}',
                        style: AppTextStyles.small(scale,
                                color: hc ? Colors.black : AppColors.tealDeep)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          if (c.cantidadHijos > 0 || c.conConyuge)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (c.conConyuge) 'Con cónyuge',
                  if (c.cantidadHijos > 0)
                    '${c.cantidadHijos} ${c.cantidadHijos == 1 ? 'hijo/a' : 'hijos/as'}',
                ].join(' · '),
                style: AppTextStyles.small(scale,
                    color: hc ? Colors.black54 : null),
              ),
            ),
        ],
      ),
    );
  }
}
