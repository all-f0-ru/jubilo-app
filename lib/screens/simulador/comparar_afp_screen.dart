import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/data/afp_aseguradoras_datos.dart';
import '../../core/pension_engine/pension_config.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_widgets.dart';

/// Comparador de AFP (comisión y rentabilidad) e información de aseguradoras.
/// Pantalla Premium: quien la abre ya pasó por el control de Premium.
class CompararAfpScreen extends StatefulWidget {
  const CompararAfpScreen({super.key});

  @override
  State<CompararAfpScreen> createState() => _CompararAfpScreenState();
}

class _CompararAfpScreenState extends State<CompararAfpScreen> {
  final _sueldoCtrl = TextEditingController(text: '1000000');
  int _fondo = 2; // Fondo C por defecto.

  @override
  void dispose() {
    _sueldoCtrl.dispose();
    super.dispose();
  }

  static String _clp(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '\$$b';
  }

  static String _pct(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  Future<void> _abrir(String url) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    mensajes.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final ink = hc ? Colors.black : AppColors.ink;
    final suave = hc ? Colors.black54 : AppColors.inkSoft;

    // El sueldo imponible tiene tope de 90 UF.
    final tope = ParametrosVigentes.valorUf * 90;
    final ingresado = double.tryParse(_sueldoCtrl.text.trim()) ?? 0;
    final sueldo = ingresado.clamp(0, tope).toDouble();

    final lista = [...AfpDatos.afp]
      ..sort((a, b) => a.comisionPct.compareTo(b.comisionPct));
    final barata = lista.first;
    final cara = lista.last;
    final ahorroAnual =
        sueldo * (cara.comisionPct - barata.comisionPct) / 100 * 12;

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Compara AFP y aseguradoras',
            style: AppTextStyles.heading(0.8, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Text('Comisión y rentabilidad de cada AFP',
                style: AppTextStyles.heading(scale * 0.85, color: ink)),
            const SizedBox(height: 8),
            Text(
              'La comisión se descuenta cada mes de tu sueldo imponible, '
              'además de tu 10% de ahorro. Cambia mucho entre AFP.',
              style: AppTextStyles.body(scale, color: suave),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sueldoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.body(scale, color: ink),
              decoration: const InputDecoration(
                labelText: 'Tu sueldo imponible mensual (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            if (ingresado > tope) ...[
              const SizedBox(height: 6),
              Text(
                'Se usa el tope imponible de 90 UF (${_clp(tope)}).',
                style: AppTextStyles.small(scale, color: suave),
              ),
            ],
            const SizedBox(height: 16),
            Text('Fondo para ver la rentabilidad',
                style: AppTextStyles.small(scale, color: suave)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < AfpDatos.fondos.length; i++)
                  ChoiceChip(
                    label: Text('Fondo ${AfpDatos.fondos[i]}'),
                    selected: _fondo == i,
                    onSelected: (_) => setState(() => _fondo = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (sueldo > 0)
              InfoBanner(
                variant: BannerVariant.info,
                fontScale: scale,
                text: 'Con tu sueldo, la diferencia entre la AFP más barata '
                    '(${barata.nombre}) y la más cara (${cara.nombre}) es '
                    '${_clp(ahorroAnual)} al año solo en comisión.',
              ),
            const SizedBox(height: 12),
            for (var i = 0; i < lista.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JubiloCard(
                  borderColor: i == 0 && !hc ? AppColors.tealDeep : null,
                  borderWidth: i == 0 ? 2 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('AFP ${lista[i].nombre}',
                                style: AppTextStyles.heading(scale * 0.75,
                                    color: ink)),
                          ),
                          if (i == 0)
                            Text('Comisión más baja',
                                style: AppTextStyles.small(scale,
                                    color: hc ? Colors.black : AppColors.tealDeep)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comisión: ${_pct(lista[i].comisionPct)}% del sueldo '
                        '(${_clp(sueldo * lista[i].comisionPct / 100)} al mes, '
                        '${_clp(sueldo * lista[i].comisionPct / 100 * 12)} '
                        'al año)',
                        style: AppTextStyles.body(scale, color: ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rentabilidad real anual, Fondo ${AfpDatos.fondos[_fondo]}: '
                        '${_pct(lista[i].rent36[_fondo])}%',
                        style: AppTextStyles.body(scale, color: suave),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              'Rentabilidad: promedio anual real de los últimos 36 meses '
              '(${AfpDatos.rentabilidadPeriodo}). Rentabilidad pasada no '
              'asegura rentabilidad futura. Comisiones de '
              '${AfpDatos.comisionesPeriodo}.',
              style: AppTextStyles.small(scale, color: suave),
            ),
            const SizedBox(height: 28),
            Text('Aseguradoras (renta vitalicia)',
                style: AppTextStyles.heading(scale * 0.85, color: ink)),
            const SizedBox(height: 8),
            InfoBanner(
              variant: BannerVariant.warning,
              fontScale: scale,
              text: 'Desde septiembre de 2025, las ofertas de renta vitalicia '
                  'se hacen solo a través del SCOMP. Cuánto te pagaría cada '
                  'compañía solo se sabe con tu certificado de saldo, '
                  'pidiendo ofertas en el SCOMP. Esta app no puede '
                  'mostrártelo.',
            ),
            const SizedBox(height: 16),
            Text(
              'Qué compañías eligió la gente entre ${AfpDatos.participacionPeriodo} '
              '(porcentaje de pensionados en renta vitalicia). Es una '
              'referencia de preferencia, no dice cuál paga más.',
              style: AppTextStyles.body(scale, color: suave),
            ),
            const SizedBox(height: 12),
            for (final a in AfpDatos.aseguradoras)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(a.nombre,
                                style: AppTextStyles.body(scale, color: ink))),
                        Text('${_pct(a.participacionPct)}%',
                            style: AppTextStyles.body(scale, color: ink)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: a.participacionPct / 25,
                      minHeight: 8,
                      color: hc ? Colors.black : AppColors.coral,
                      backgroundColor: hc ? Colors.black12 : AppColors.creamDeep,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'La tasa promedio de las rentas vitalicias del sistema fue '
              '${_pct(AfpDatos.tasaPromedioRentaVitalicia)}% en el primer '
              'semestre de 2026.',
              style: AppTextStyles.small(scale, color: suave),
            ),
            const SizedBox(height: 12),
            Text('Cómo obtener ofertas reales',
                style: AppTextStyles.heading(scale * 0.75, color: ink)),
            const SizedBox(height: 6),
            Text(
              '1. Pide tu certificado de saldo a tu AFP.\n'
              '2. Solicita ofertas en el SCOMP (tu AFP o un asesor '
              'previsional inscrito te ayudan).\n'
              '3. Compara las ofertas de las compañías y de retiro programado '
              'antes de decidir.',
              style: AppTextStyles.body(scale, color: ink),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => _abrir('https://www.spensiones.cl'),
                  child: const Text('Superintendencia de Pensiones'),
                ),
                TextButton(
                  onPressed: () => _abrir(
                      'https://www.cmfchile.cl/educa/621/w3-propertyvalue-567.html'),
                  child: const Text('CMF: Rentas Vitalicias'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Datos referenciales de la Superintendencia de Pensiones. '
              'No son una recomendación ni una oferta.',
              style: AppTextStyles.small(scale, color: suave),
            ),
          ],
        ),
      ),
    );
  }
}
