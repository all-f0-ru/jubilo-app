import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/simulacion_guardada.dart';
import '../../core/models/simulador_models.dart';
import '../../core/pension_engine/modalidades_mixtas.dart';
import '../../core/pension_engine/pension_config.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/respuestas_encuesta_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/simulaciones_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/premium_sheet.dart';
import 'mis_simulaciones_screen.dart';

/// Las dos modalidades combinadas que tienen calculadora propia.
enum ModalidadMixta { temporalVitalicia, rvConRp }

String _puntos(String digitos) {
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

String _clp(double v) => '\$${_puntos(v.round().toString())}';

String _uf(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

class _FormatoMiles extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    var d = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return const TextEditingValue(text: '');
    if (d.length > 12) d = d.substring(0, 12);
    final t = _puntos(d);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Calculadora de la Renta Temporal con Renta Vitalicia Diferida y de la
/// Renta Vitalicia Inmediata con Retiro Programado, con PGU y BAC.
///
/// Es una referencia educativa: usa una mortalidad aproximada (como los
/// scripts del cliente), no considera beneficiarios ni comisiones de las
/// aseguradoras, y no es una oferta ni una cotización.
class CalculadoraMixtaScreen extends StatefulWidget {
  final SimuladorRespuestas respuestas;
  final ModalidadMixta modalidad;

  const CalculadoraMixtaScreen({
    super.key,
    required this.respuestas,
    required this.modalidad,
  });

  @override
  State<CalculadoraMixtaScreen> createState() => _CalculadoraMixtaScreenState();
}

class _CalculadoraMixtaScreenState extends State<CalculadoraMixtaScreen> {
  static const double _rentabilidadReal = 0.035;

  final TextEditingController _saldoCtrl = TextEditingController();
  int _edad = 63;
  int _aniosCotizados = 25;
  int _pctRv = 50; // solo RV + RP
  int _aniosTemporal = 2; // solo Temporal + Vitalicia
  int _relacionPct = 150; // solo Temporal + Vitalicia

  bool _calculado = false;
  bool _recienGuardada = false;
  final ScrollController _scroll = ScrollController();

  bool get _esRvRp => widget.modalidad == ModalidadMixta.rvConRp;
  int? get _saldo => int.tryParse(_saldoCtrl.text.replaceAll('.', ''));

  @override
  void initState() {
    super.initState();
    final recordados = context.read<RespuestasEncuestaProvider>();
    final guardada = recordados.edad ?? context.read<SettingsProvider>().edad;
    if (guardada != null) _edad = guardada.clamp(50, 65);
    if (recordados.saldoClp != null) {
      _saldoCtrl.text = _puntos('${recordados.saldoClp}');
    }
    if (recordados.aniosCotizados != null) {
      _aniosCotizados = recordados.aniosCotizados!.clamp(0, 45);
    }
  }

  @override
  void dispose() {
    _saldoCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _actualizar(VoidCallback f) {
    setState(() {
      f();
      _recienGuardada = false;
    });
    context.read<RespuestasEncuestaProvider>().recordarDatos(
        saldoClp: _saldo, edad: _edad, aniosCotizados: _aniosCotizados);
  }

  /// Ejecuta el cálculo con los datos actuales. Devuelve el resultado, una
  /// [ModalidadesMixtasException] si hay un dato inválido, o null si falta
  /// el saldo.
  Object? _ejecutar() {
    final saldo = _saldo;
    if (saldo == null || saldo <= 0) return null;
    try {
      final minimo = minimoAniosBac(widget.respuestas.sexo);
      if (_esRvRp) {
        return simularRvInmediataConRp(
          saldoClp: saldo.toDouble(),
          edad: _edad,
          pctRv: _pctRv / 100,
          tasaRv: ParametrosVigentes.tasaReferenciaVejez,
          tasaRp: ParametrosVigentes.tasaRetiroProgramado,
          rentabilidad: _rentabilidadReal,
          valorUf: ParametrosVigentes.valorUf,
          aniosCotizados: _aniosCotizados.toDouble(),
          minimoAnios: minimo,
        );
      }
      return simularRentaTemporalVitalicia(
        saldoClp: saldo.toDouble(),
        edad: _edad,
        aniosTemporal: _aniosTemporal,
        relacion: _relacionPct / 100,
        tasa: ParametrosVigentes.tasaReferenciaVejez,
        valorUf: ParametrosVigentes.valorUf,
        aniosCotizados: _aniosCotizados.toDouble(),
        minimoAnios: minimo,
      );
    } on ModalidadesMixtasException catch (e) {
      return e;
    }
  }

  /// Botón "Calcular mi pensión": muestra el resultado y, si la persona no
  /// tiene Premium, le ofrece desbloquearlo; con Premium pregunta si quiere
  /// guardar la simulación.
  Future<void> _presionarCalcular() async {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final premium = context.read<PremiumProvider>();
    setState(() => _calculado = true);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (!premium.esPremium) {
      final ok = await mostrarPremiumSheet(context);
      if (!ok || !mounted) return;
    }
    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Guardar esta simulación?'),
        content: const Text(
            'Se guarda con el monto y la hora de hoy. La verás en "Mis simulaciones".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Ahora no')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (guardar == true && mounted) await _guardarActual();
  }

  /// Botón "Guardar" de la tarjeta (función Premium).
  Future<void> _guardar() async {
    HapticFeedback.selectionClick();
    final premium = context.read<PremiumProvider>();
    if (!premium.esPremium) {
      final ok = await mostrarPremiumSheet(context);
      if (!ok || !mounted) return;
    }
    await _guardarActual();
  }

  Future<void> _guardarActual() async {
    final simulaciones = context.read<SimulacionesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final saldo = _saldo;
    final r = _ejecutar();
    if (saldo == null || r == null || r is ModalidadesMixtasException) return;

    double clp;
    double uf;
    String modalidad;
    if (r is ResultadoRvRp) {
      final f = r.filas.first;
      clp = f.rvClp + f.rpClp;
      uf = f.rvUf + f.rpUf;
      modalidad = SimulacionGuardada.rvConRp;
    } else {
      final t = r as ResultadoTemporalVitalicia;
      clp = t.temporalClp;
      uf = t.temporalUf;
      modalidad = SimulacionGuardada.temporalVitalicia;
    }

    final ahora = DateTime.now();
    await simulaciones.guardar(
      SimulacionGuardada(
        id: '${ahora.microsecondsSinceEpoch}',
        fecha: ahora,
        modalidad: modalidad,
        saldoClp: saldo,
        edad: _edad,
        sexo: widget.respuestas.sexo,
        conConyuge: false,
        pensionMensualClp: clp,
        pensionMensualUf: uf,
        valorUf: ParametrosVigentes.valorUf,
        tasa: ParametrosVigentes.tasaReferenciaVejez,
      ),
    );
    if (!mounted) return;
    setState(() => _recienGuardada = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Simulación guardada')),
    );
  }

  Widget _buildGuardar(double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    final premium = context.watch<PremiumProvider>().esPremium;
    return JubiloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_add_outlined, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text('¿Quieres guardar esta simulación?',
                    style: AppTextStyles.heading(scale * 0.75,
                        color: hc ? Colors.black : null)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Se guarda con el monto y la hora de hoy.',
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : null)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _recienGuardada
                ? OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(JubiloPageRoute(
                        builder: (_) => const MisSimulacionesScreen())),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Guardada · Ver mis simulaciones'),
                  )
                : ElevatedButton.icon(
                    onPressed: _guardar,
                    icon: Icon(premium
                        ? Icons.bookmark_add_outlined
                        : Icons.lock_outline_rounded),
                    label: Text(
                        premium ? 'Guardar simulación' : 'Guardar (Premium)'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto, double scale, bool hc) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(texto,
            style: AppTextStyles.heading(scale * 0.8,
                color: hc ? Colors.black : null)),
      );

  Widget _chipOpcion(String label, bool sel, VoidCallback onTap, double scale,
      bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      showCheckmark: false,
      selectedColor: accent,
      backgroundColor: Colors.white,
      side: BorderSide(color: accent, width: 1.5),
      labelStyle: TextStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        color: sel ? Colors.white : accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;
    final nombre = _esRvRp
        ? 'Renta Vitalicia con Retiro Programado'
        : 'Renta Temporal con Vitalicia Diferida';

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(nombre,
            style: AppTextStyles.heading(0.7, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            _buildResultado(scale, hc),
            const SizedBox(height: 28),

            _titulo('Tu edad al pensionarte', scale, hc),
            StepperNumero(
              valor: _edad,
              minimo: 50,
              maximo: 65,
              sufijo: 'años',
              highContrast: hc,
              fontScale: scale,
              onChanged: (v) => _actualizar(() => _edad = v),
            ),
            const SizedBox(height: 28),

            _titulo('Tu saldo ahorrado', scale, hc),
            TextField(
              controller: _saldoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_FormatoMiles()],
              style: AppTextStyles.body(scale, color: hc ? Colors.black : null),
              decoration: InputDecoration(
                hintText: '100.000.000',
                prefixText: '\$ ',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: hc ? Colors.black : AppColors.creamDeep, width: 2),
                ),
              ),
              onChanged: (_) => _actualizar(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in const [50, 100, 140, 200])
                  _chipOpcion('$m millones', _saldo == m * 1000000, () {
                    _saldoCtrl.text = _puntos('${m * 1000000}');
                    _actualizar(() {});
                  }, scale, hc),
              ],
            ),
            const SizedBox(height: 28),

            if (_esRvRp) ...[
              _titulo('¿Qué parte va a Renta Vitalicia?', scale, hc),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in const [30, 50, 70])
                    _chipOpcion('$p%', _pctRv == p,
                        () => _actualizar(() => _pctRv = p), scale, hc),
                ],
              ),
              const SizedBox(height: 6),
              Text('El resto ${100 - _pctRv}% queda en Retiro Programado.',
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black54 : null)),
            ] else ...[
              _titulo('Años de Renta Temporal', scale, hc),
              StepperNumero(
                valor: _aniosTemporal,
                minimo: 1,
                maximo: 5,
                sufijo: _aniosTemporal == 1 ? 'año' : 'años',
                highContrast: hc,
                fontScale: scale,
                onChanged: (v) => _actualizar(() => _aniosTemporal = v),
              ),
              const SizedBox(height: 28),
              _titulo('Renta temporal comparada con la vitalicia', scale, hc),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in const [100, 150, 200])
                    _chipOpcion('$p%', _relacionPct == p,
                        () => _actualizar(() => _relacionPct = p), scale, hc),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  'Con $_relacionPct%, la renta temporal es '
                  '${(_relacionPct / 100).toString().replaceAll('.', ',')} '
                  'veces la vitalicia.',
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black54 : null)),
            ],
            const SizedBox(height: 28),

            _titulo('Años cotizados (para el BAC)', scale, hc),
            StepperNumero(
              valor: _aniosCotizados,
              minimo: 0,
              maximo: 45,
              sufijo: 'años',
              highContrast: hc,
              fontScale: scale,
              onChanged: (v) => _actualizar(() => _aniosCotizados = v),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _ejecutar() is ModalidadesMixtasException ||
                        _ejecutar() == null
                    ? null
                    : _presionarCalcular,
                icon: const Icon(Icons.calculate_outlined),
                label: Text(
                    _calculado ? 'Calcular de nuevo' : 'Calcular mi pensión'),
              ),
            ),
            const SizedBox(height: 28),

            Plegable(
              titulo: 'Supuestos de este cálculo',
              icono: Icons.info_outline_rounded,
              color: accent,
              highContrast: hc,
              fontScale: scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _supuesto('Valor de la UF',
                      '\$${_puntos(ParametrosVigentes.valorUf.round().toString())}',
                      scale, hc),
                  _supuesto(
                      'Tasa de la renta vitalicia',
                      '${(ParametrosVigentes.tasaReferenciaVejez * 100).toStringAsFixed(2).replaceAll('.', ',')}%',
                      scale, hc),
                  if (_esRvRp) ...[
                    _supuesto(
                        'Tasa técnica del retiro programado',
                        '${(ParametrosVigentes.tasaRetiroProgramado * 100).toStringAsFixed(2).replaceAll('.', ',')}%',
                        scale, hc),
                    _supuesto('Rentabilidad real de tu fondo', '3,5% al año',
                        scale, hc),
                  ],
                  _supuesto('Mortalidad',
                      'Aproximada (esperanza de vida de 19,5 años a los 65)',
                      scale, hc),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Estimación educativa, en valores de hoy y antes de descuentos '
              'de salud e impuestos. No incluye comisiones ni márgenes de las '
              'aseguradoras, ni beneficiarios. Los montos definitivos se '
              'obtienen cotizando en SCOMP.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supuesto(String k, String v, double scale, bool hc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(k,
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black54 : null)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black : AppColors.ink)),
            ),
          ],
        ),
      );

  // ---------------- Resultado ----------------

  Widget _buildResultado(double scale, bool hc) {
    final r = _ejecutar();
    if (r is ModalidadesMixtasException) {
      return InfoBanner(
          variant: BannerVariant.warning, fontScale: scale, text: r.mensaje);
    }
    if (r == null || !_calculado) {
      return JubiloCard(
        child: Row(
          children: [
            IconBadge(
                icon: Icons.savings_outlined,
                color: hc ? Colors.black : AppColors.teal),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                  r == null
                      ? 'Escribe tu saldo para ver tu pensión'
                      : 'Presiona "Calcular mi pensión" para ver tu resultado',
                  style: AppTextStyles.body(scale,
                      color: hc ? Colors.black87 : null)),
            ),
          ],
        ),
      );
    }
    final cuerpo = r is ResultadoRvRp
        ? _resultadoRvRp(r, scale, hc)
        : _resultadoTemporal(r as ResultadoTemporalVitalicia, scale, hc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cuerpo,
        const SizedBox(height: 16),
        _buildGuardar(scale, hc),
      ],
    );
  }

  Widget _tarjetaCifra({
    required String titulo,
    required double clp,
    required double uf,
    required String bajada,
    required double scale,
    required bool hc,
  }) {
    final accent = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      borderColor: accent,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : null)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_clp(clp),
                style: AppTextStyles.display(scale,
                    color: hc ? Colors.black : AppColors.tealDeep)),
          ),
          Text(bajada,
              style: AppTextStyles.body(scale,
                  color: hc ? Colors.black87 : null)),
          const SizedBox(height: 8),
          Text('${_uf(uf)} UF al mes',
              style: AppTextStyles.heading(scale * 0.9,
                  color: hc ? Colors.black : AppColors.tealDeep)),
        ],
      ),
    );
  }

  Widget _filaDato(String k, String v, double scale, bool hc,
      {bool fuerte = false}) {
    final st = AppTextStyles.body(scale, color: hc ? Colors.black : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  style: fuerte
                      ? st.copyWith(fontWeight: FontWeight.w800)
                      : st)),
          Text(v,
              style: fuerte ? st.copyWith(fontWeight: FontWeight.w800) : st),
        ],
      ),
    );
  }

  Widget _resultadoTemporal(
      ResultadoTemporalVitalicia r, double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    final fin = r.edadInicioVitalicia;
    final aviso = r.vitalicioClp > 789139 * 0.95
        ? 'Tu renta vitalicia está cerca del límite para recibir la PGU '
            'completa. Confirma el monto real con tu AFP o el IPS.'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaCifra(
          titulo: 'Renta temporal',
          clp: r.temporalClp,
          uf: r.temporalUf,
          bajada: 'al mes, desde los $_edad hasta los $fin años',
          scale: scale,
          hc: hc,
        ),
        const SizedBox(height: 12),
        _tarjetaCifra(
          titulo: 'Renta vitalicia diferida',
          clp: r.vitalicioClp,
          uf: r.vitalicioUf,
          bajada: 'al mes, desde los $fin años y de por vida',
          scale: scale,
          hc: hc,
        ),
        const SizedBox(height: 12),
        JubiloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Desde los $fin años, cada mes',
                  style: AppTextStyles.heading(scale * 0.75,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 6),
              _filaDato('Renta vitalicia', _clp(r.vitalicioClp), scale, hc),
              _filaDato('PGU estimada', _clp(r.pguClp), scale, hc),
              _filaDato('BAC estimado', _clp(r.bacClp), scale, hc),
              const Divider(height: 18),
              _filaDato('Total', _clp(r.totalDesdeVitalicioClp), scale, hc,
                  fuerte: true),
            ],
          ),
        ),
        if (aviso != null) ...[
          const SizedBox(height: 12),
          InfoBanner(
              variant: BannerVariant.info, fontScale: scale, text: aviso),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          AppChip(label: 'La vitalicia es fija en UF', color: accent),
          AppChip(label: 'Es irrevocable', color: accent),
        ]),
      ],
    );
  }

  Widget _resultadoRvRp(ResultadoRvRp r, double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    final inicio = r.filas.first;
    final edades = <int>{_edad, 65, 70, 75, 80, 85, 90}
        .where((e) => e >= _edad)
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaCifra(
          titulo: 'Al pensionarte, a los $_edad años',
          clp: inicio.rvClp + inicio.rpClp,
          uf: inicio.rvUf + inicio.rpUf,
          bajada: 'al mes, entre renta vitalicia y retiro programado',
          scale: scale,
          hc: hc,
        ),
        const SizedBox(height: 12),
        JubiloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('De dónde viene',
                  style: AppTextStyles.heading(scale * 0.75,
                      color: hc ? Colors.black : null)),
              const SizedBox(height: 6),
              _filaDato('Renta vitalicia (fija)', _clp(inicio.rvClp), scale, hc),
              Text('${_uf(inicio.rvUf)} UF al mes',
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black54 : null)),
              _filaDato('Retiro programado (el primer año)',
                  _clp(inicio.rpClp), scale, hc),
              Text('${_uf(inicio.rpUf)} UF al mes',
                  style: AppTextStyles.small(scale,
                      color: hc ? Colors.black54 : null)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Plegable(
          titulo: 'Cómo cambia con los años',
          icono: Icons.timeline_rounded,
          color: accent,
          abiertoInicial: true,
          highContrast: hc,
          fontScale: scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in edades) _filaEdad(r.filaEdad(e)!, scale, hc),
              const SizedBox(height: 6),
              Text(
                'Desde los 65 se suman la PGU y el BAC. El retiro programado '
                'se recalcula cada año y suele bajar; la renta vitalicia '
                'queda fija en UF.',
                style: AppTextStyles.small(scale,
                    color: hc ? Colors.black54 : null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          AppChip(label: 'Parte fija y parte variable', color: accent),
          AppChip(label: 'El saldo del retiro es tuyo', color: accent),
        ]),
      ],
    );
  }

  Widget _filaEdad(FilaRvRp f, double scale, bool hc) {
    final extra = f.pguClp + f.bacClp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filaDato('A los ${f.edad} años', _clp(f.totalClp), scale, hc,
              fuerte: true),
          Text(
            'Renta vitalicia ${_clp(f.rvClp)} · Retiro ${_clp(f.rpClp)}'
            '${extra > 0 ? ' · PGU y BAC ${_clp(extra)}' : ''}',
            style:
                AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
          ),
        ],
      ),
    );
  }
}
