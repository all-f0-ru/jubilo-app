import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/pension_engine/cnu_engine.dart';
import '../../core/pension_engine/pension_config.dart';
import '../../core/pension_engine/renta_vitalicia.dart';
import '../../core/pension_engine/retiro_programado.dart';
import '../../core/pension_engine/tm2020_assets.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/respuestas_encuesta_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/simulaciones_provider.dart';
import '../../core/models/simulacion_guardada.dart';
import '../../core/models/simulador_models.dart';
import '../../core/widgets/premium_sheet.dart';
import 'mis_simulaciones_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/boton_escuchar.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/nota_transparencia.dart';

/// Estimación de la pensión mensual en una Renta Vitalicia Inmediata,
/// usando el motor actuarial (tablas TM2020, tasa de referencia y UF).
///
/// El resultado aparece arriba y se actualiza solo cada vez que la persona
/// cambia un dato, así no hace falta apretar un botón de "calcular".
///
/// Es una referencia educativa: no es una cotización de una compañía de
/// seguros. Por ahora considera a la persona sola o con un cónyuge; los
/// hijos como beneficiarios todavía no están incluidos en el cálculo.
class SimuladorEstimacionScreen extends StatefulWidget {
  final SimuladorRespuestas respuestas;

  /// Qué algoritmo usa el cálculo. Cada modalidad tiene el suyo.
  final ModalidadCalculo modalidad;

  const SimuladorEstimacionScreen({
    super.key,
    required this.respuestas,
    this.modalidad = ModalidadCalculo.rentaVitalicia,
  });

  @override
  State<SimuladorEstimacionScreen> createState() =>
      _SimuladorEstimacionScreenState();
}

/// Modalidades que tienen cálculo propio en la app.
enum ModalidadCalculo { rentaVitalicia, retiroProgramado }

/// Resultado común que muestra la pantalla, venga del algoritmo que venga.
/// Los nombres calzan con los de ResultadoRentaVitalicia.
class _Salida {
  final double primaUf; // saldo en UF
  final double valorUf;
  final double pensionMensualUf;
  final double pensionMensualClp;
  final double cnuTotal;
  final double cnuConyuge;
  final double tasaRentaVitalicia; // tasa usada (RVI o RP)
  final double umbralMinimoUf;
  final bool cumpleUmbralMinimo;

  const _Salida({
    required this.primaUf,
    required this.valorUf,
    required this.pensionMensualUf,
    required this.pensionMensualClp,
    required this.cnuTotal,
    required this.cnuConyuge,
    required this.tasaRentaVitalicia,
    required this.umbralMinimoUf,
    required this.cumpleUmbralMinimo,
  });
}

/// Agrega puntos de miles a un texto de dígitos. Ej: 1200000 -> 1.200.000
String _conPuntos(String digitos) {
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

/// Mientras la persona escribe el saldo, le va poniendo los puntos de miles.
class _MilesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue(text: '');
    if (digitos.length > 12) digitos = digitos.substring(0, 12);
    final texto = _conPuntos(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

int _acotar(int valor, int minimo, int maximo) {
  if (valor < minimo) return minimo;
  if (valor > maximo) return maximo;
  return valor;
}

class _SimuladorEstimacionScreenState extends State<SimuladorEstimacionScreen> {
  static const List<int> _saldosRapidosMillones = [10, 20, 30, 50];

  final TextEditingController _saldoCtrl = TextEditingController();

  int _edad = 65;
  int _edadConyuge = 62;
  String? _conyugeSexo; // 'F' | 'M'

  Map<String, MortalityTable>? _tablas;
  String? _errorCarga;

  _Salida? _resultado;
  String? _errorCalculo;

  bool get _esRp => widget.modalidad == ModalidadCalculo.retiroProgramado;

  /// true cuando la simulación que se ve ya fue guardada (se apaga si la
  /// persona cambia algún dato).
  bool _recienGuardada = false;

  /// true cuando la persona ya presionó "Calcular mi pensión". Hasta
  /// entonces no se muestra el resultado.
  bool _calculado = false;
  final ScrollController _scroll = ScrollController();

  bool get _conConyuge => widget.respuestas.estadoCivil == 'Casado/a';

  int? get _saldo => int.tryParse(_saldoCtrl.text.replaceAll('.', ''));

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();
    final recordados = context.read<RespuestasEncuestaProvider>();
    _edad = recordados.edad != null
        ? _acotar(recordados.edad!, 50, 100)
        : _edadInicial(settings);
    _edadConyuge = _acotar(_edad, 18, 100);
    final sexoC = recordados.extraTexto('conyugeSexo');
    if (sexoC == 'F' || sexoC == 'M') _conyugeSexo = sexoC;
    final edadC = recordados.extraInt('conyugeEdad');
    if (edadC != null) _edadConyuge = _acotar(edadC, 18, 100);
    if (recordados.saldoClp != null) {
      _saldoCtrl.text = _conPuntos('${recordados.saldoClp}');
    }

    cargarTablasTm2020DesdeAssets().then((tablas) {
      if (!mounted) return;
      setState(() {
        _tablas = tablas;
        _calcular();
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _errorCarga =
          'No pudimos cargar los datos del cálculo. Cierra y vuelve a '
          'abrir la app.');
    });
  }

  @override
  void dispose() {
    _saldoCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Edad de partida: la que la persona ya contó en "Aprender" o, si no, un
  /// valor típico según el rango que eligió en el simulador.
  int _edadInicial(SettingsProvider settings) {
    final guardada = settings.edad;
    if (guardada != null && settings.sexo == widget.respuestas.sexo) {
      return _acotar(guardada, 50, 100);
    }
    switch (widget.respuestas.rangoEdad) {
      case '55 o menos':
        return 55;
      case '56 a 60':
        return 60;
      case '61 a 64':
        return 63;
      default:
        return 65;
    }
  }

  /// Cambia un dato y recalcula de inmediato.
  void _actualizar(VoidCallback cambio) {
    setState(() {
      cambio();
      _recienGuardada = false;
      _calcular();
    });
    context
        .read<RespuestasEncuestaProvider>()
        .recordarDatos(saldoClp: _saldo, edad: _edad);
    context.read<RespuestasEncuestaProvider>().recordarExtras({
      'conyugeSexo': ?_conyugeSexo,
      'conyugeEdad': _edadConyuge,
    });
  }

  /// Botón "Calcular mi pensión": muestra el resultado y, si la persona no
  /// tiene Premium, le ofrece desbloquearlo en una pantalla completa.
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
    // Con Premium: se pregunta si quiere guardar esta simulación.
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

  void _verMisSimulaciones() {
    Navigator.of(context).push(
      JubiloPageRoute(builder: (_) => const MisSimulacionesScreen()),
    );
  }

  /// Guarda la simulación actual (función Premium). Si la persona aún no
  /// tiene Premium, primero se le ofrece desbloquearlo.
  Future<void> _guardar() async {
    HapticFeedback.selectionClick();
    final premium = context.read<PremiumProvider>();

    if (!premium.esPremium) {
      final desbloqueado = await mostrarPremiumSheet(context);
      if (!desbloqueado || !mounted) return;
    }

    await _guardarActual();
  }

  /// Guarda la simulación que se ve ahora (ya con Premium confirmado).
  Future<void> _guardarActual() async {
    final simulaciones = context.read<SimulacionesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final r = _resultado;
    final saldo = _saldo;
    if (r == null || saldo == null) return;

    final ahora = DateTime.now();
    await simulaciones.guardar(
      SimulacionGuardada(
        id: '${ahora.microsecondsSinceEpoch}',
        fecha: ahora,
        modalidad: _esRp
            ? SimulacionGuardada.retiroProgramado
            : SimulacionGuardada.rentaVitalicia,
        saldoClp: saldo,
        edad: _edad,
        sexo: widget.respuestas.sexo,
        conConyuge: _conConyuge,
        pensionMensualClp: r.pensionMensualClp,
        pensionMensualUf: r.pensionMensualUf,
        valorUf: r.valorUf,
        tasa: r.tasaRentaVitalicia,
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
                    onPressed: _verMisSimulaciones,
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

  /// Fecha de nacimiento tal que, a la fecha de hoy, la persona tenga
  /// exactamente [edad] años cumplidos.
  DateTime _nacimientoParaEdad(DateTime hoy, int edad) {
    var dia = hoy.day;
    if (hoy.month == 2 && dia == 29) dia = 28;
    return DateTime(hoy.year - edad, hoy.month, dia);
  }

  String _codigoSexo(String sexo) => sexo == 'Mujer' ? 'F' : 'M';

  /// Calcula con los datos actuales. No llama a setState: se usa siempre
  /// desde dentro de uno.
  void _calcular() {
    _resultado = null;
    _errorCalculo = null;

    final tablas = _tablas;
    final saldoClp = _saldo;
    if (tablas == null || saldoClp == null || saldoClp <= 0) return;
    if (_conConyuge && _conyugeSexo == null) return;

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final beneficiarios = <BeneficiarioRvi>[];
    if (_conConyuge) {
      beneficiarios.add(
        BeneficiarioRvi(
          tipo: 'conyuge',
          sexo: _conyugeSexo!,
          fechaNacimiento: _nacimientoParaEdad(hoy, _edadConyuge),
        ),
      );
    }

    final grupo = GrupoFamiliarRvi(
      afiliadoSexo: _codigoSexo(widget.respuestas.sexo),
      afiliadoFechaNacimiento: _nacimientoParaEdad(hoy, _edad),
      beneficiarios: beneficiarios,
    );

    final saldoUf = saldoClp / ParametrosVigentes.valorUf;

    try {
      if (_esRp) {
        final r = calcularRetiroProgramado(
          saldoUf: saldoUf,
          grupoFamiliar: grupo,
          parametros: ParametrosRp(
            fechaReferencia: hoy,
            tasaRp: ParametrosVigentes.tasaRetiroProgramado,
            versionTasa: ParametrosVigentes.tasaRetiroProgramadoFuente,
          ),
          valorUf: ParametrosVigentes.valorUf,
          tablas: tablas,
        );
        _resultado = _Salida(
          primaUf: r.saldoTotalUf,
          valorUf: r.valorUf,
          pensionMensualUf: r.pensionMensualUf,
          pensionMensualClp: r.pensionMensualClp,
          cnuTotal: r.cnuTotal,
          cnuConyuge: r.cnuConyuge,
          tasaRentaVitalicia: r.tasaRp,
          umbralMinimoUf: 0,
          cumpleUmbralMinimo: true,
        );
      } else {
        final r = calcularRentaVitalicia(
          primaUf: saldoUf,
          grupoFamiliar: grupo,
          parametros: ParametrosRvi(
            fechaReferencia: hoy,
            tasaReferencia: ParametrosVigentes.tasaReferencia,
          ),
          valorUf: ParametrosVigentes.valorUf,
          tablas: tablas,
        );
        _resultado = _Salida(
          primaUf: r.primaUf,
          valorUf: r.valorUf,
          pensionMensualUf: r.pensionMensualUf,
          pensionMensualClp: r.pensionMensualClp,
          cnuTotal: r.cnuTotal,
          cnuConyuge: r.cnuConyuge,
          tasaRentaVitalicia: r.tasaRentaVitalicia,
          umbralMinimoUf: r.umbralMinimoUf,
          cumpleUmbralMinimo: r.cumpleUmbralMinimo,
        );
      }
    } on CNUException catch (e) {
      _errorCalculo = e.message;
    } on RentaVitaliciaException catch (e) {
      _errorCalculo = e.message;
    } on RetiroProgramadoException catch (e) {
      _errorCalculo = e.message;
    }
  }

  // ---------------------------------------------------------------
  // Formatos (sin dependencias externas)
  // ---------------------------------------------------------------

  String _fmtClp(double v) => '\$${_conPuntos(v.round().toString())}';

  String _fmtUf(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  /// Valor de la UF en pesos, con miles y 2 decimales. Ej: $41.152,13
  String _fmtValorUf(double v) {
    final partes = v.toStringAsFixed(2).split('.');
    return '\$${_conPuntos(int.parse(partes[0]).toString())},${partes[1]}';
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  Widget _titulo(String texto, double scale, bool hc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style:
            AppTextStyles.heading(scale * 0.8, color: hc ? Colors.black : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final reducir = reduceMotion(context);

    // Qué se muestra arriba: carga, error, aviso inicial o resultado.
    final String estado;
    if (_errorCarga != null) {
      estado = 'error-carga';
    } else if (_tablas == null) {
      estado = 'carga';
    } else if (_errorCalculo != null) {
      estado = 'error-calculo';
    } else if (_resultado == null || !_calculado) {
      estado = 'vacio';
    } else {
      estado = 'resultado';
    }

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tu pensión',
            style: AppTextStyles.heading(0.85, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            AnimatedSwitcher(
              duration:
                  reducir ? Duration.zero : const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(estado),
                child: _buildArriba(estado, scale, hc),
              ),
            ),
            const SizedBox(height: 28),

            _titulo('Tu edad', scale, hc),
            StepperNumero(
              valor: _edad,
              minimo: 50,
              maximo: 100,
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
              inputFormatters: [_MilesFormatter()],
              style: AppTextStyles.body(scale, color: hc ? Colors.black : null),
              decoration: InputDecoration(
                hintText: '25.000.000',
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
                for (final m in _saldosRapidosMillones)
                  _buildSaldoRapido(m, scale, hc),
              ],
            ),

            const SizedBox(height: 16),
            Plegable(
              titulo: '¿Dónde veo mi saldo?',
              icono: Icons.help_outline_rounded,
              color: hc ? Colors.black : AppColors.teal,
              highContrast: hc,
              fontScale: scale,
              child: Text(
                'Pide tu Certificado de Saldo en el sitio o la app de tu AFP, '
                'con tu ClaveÚnica. También puedes ir a una sucursal con tu '
                'cédula. Usa el monto que aparece como saldo total.',
                style: AppTextStyles.body(scale,
                    color: hc ? Colors.black87 : null),
              ),
            ),

            if (_conConyuge) ...[
              const SizedBox(height: 28),
              _titulo('Tu cónyuge', scale, hc),
              Row(
                children: [
                  Expanded(
                    child: OptionCard(
                      label: 'Mujer',
                      selected: _conyugeSexo == 'F',
                      highContrast: hc,
                      onTap: () => _actualizar(() => _conyugeSexo = 'F'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OptionCard(
                      label: 'Hombre',
                      selected: _conyugeSexo == 'M',
                      highContrast: hc,
                      onTap: () => _actualizar(() => _conyugeSexo = 'M'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StepperNumero(
                valor: _edadConyuge,
                minimo: 18,
                maximo: 100,
                sufijo: 'años',
                highContrast: hc,
                fontScale: scale,
                onChanged: (v) => _actualizar(() => _edadConyuge = v),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resultado == null ? null : _presionarCalcular,
                icon: const Icon(Icons.calculate_outlined),
                label: Text(_calculado ? 'Calcular de nuevo' : 'Calcular mi pensión'),
              ),
            ),

            if (widget.respuestas.tieneHijos) ...[
              const SizedBox(height: 24),
              InfoBanner(
                variant: BannerVariant.info,
                fontScale: scale,
                text: 'Tus hijos/as aún no se incluyen en este cálculo.',
              ),
            ],

            const SizedBox(height: 28),
            Text(
              _esRp
                  ? 'Estimación educativa. El monto real lo calcula tu AFP.'
                  : 'Estimación educativa. No es una oferta de una aseguradora.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoRapido(int millones, double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    final seleccionado = _saldo == millones * 1000000;
    return ChoiceChip(
      label: Text('$millones millones'),
      selected: seleccionado,
      showCheckmark: false,
      selectedColor: accent,
      backgroundColor: Colors.white,
      side: BorderSide(color: accent, width: 1.5),
      labelStyle: TextStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        color: seleccionado ? Colors.white : accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _saldoCtrl.text = _conPuntos('${millones * 1000000}');
        _actualizar(() {});
      },
    );
  }

  Widget _buildArriba(String estado, double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;

    switch (estado) {
      case 'error-carga':
        return InfoBanner(
          variant: BannerVariant.warning,
          fontScale: scale,
          text: _errorCarga ?? '',
        );
      case 'error-calculo':
        return InfoBanner(
          variant: BannerVariant.warning,
          fontScale: scale,
          text: _errorCalculo ?? '',
        );
      case 'carga':
        return JubiloCard(
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Preparando el cálculo…',
                    style: AppTextStyles.body(scale,
                        color: hc ? Colors.black87 : null)),
              ),
            ],
          ),
        );
      case 'resultado':
        return _buildResultado(_resultado!, scale, hc);
      default:
        return JubiloCard(
          child: Row(
            children: [
              IconBadge(icon: Icons.savings_outlined, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _conConyuge && _conyugeSexo == null
                      ? 'Escribe tu saldo y elige el sexo de tu cónyuge'
                      : 'Escribe tu saldo para ver tu pensión',
                  style: AppTextStyles.body(scale,
                      color: hc ? Colors.black87 : null),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildResultado(_Salida r, double scale, bool hc) {
    final accent = hc ? Colors.black : AppColors.teal;
    final saldoClp = r.primaUf * r.valorUf;
    final tasa =
        (r.tasaRentaVitalicia * 100).toStringAsFixed(2).replaceAll('.', ',');

    final bajo = !r.cumpleUmbralMinimo;
    final tonoCifra = bajo
        ? (hc ? Colors.black54 : AppColors.inkSoft)
        : (hc ? Colors.black : AppColors.tealDeep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Con saldo bajo, primero el aviso y después la cifra (atenuada).
        if (bajo) ...[
          InfoBanner(
            variant: BannerVariant.warning,
            fontScale: scale,
            text: 'Con este saldo la pensión queda bajo el mínimo de '
                '${_fmtUf(r.umbralMinimoUf)} UF para contratar una renta '
                'vitalicia. Consulta por otras modalidades y por la PGU.',
          ),
          const SizedBox(height: 12),
        ],
        JubiloCard(
          borderColor: bajo ? null : accent,
          borderWidth: bajo ? 1 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bajo ? 'MONTO REFERENCIAL' : 'PENSIÓN MENSUAL ESTIMADA',
                style: TextStyle(
                  color: hc ? Colors.black54 : AppColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              // Al cambiar el monto, la cifra "sube" suavemente hasta su valor.
              TweenAnimationBuilder<double>(
                key: ValueKey(r.pensionMensualClp.round()),
                tween: Tween<double>(
                  begin: r.pensionMensualClp * 0.92,
                  end: r.pensionMensualClp,
                ),
                duration: reduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, valor, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmtClp(valor),
                    style: AppTextStyles.display(scale, color: tonoCifra),
                  ),
                ),
              ),
              Text(
                _esRp ? 'al mes, el primer año' : 'al mes, de por vida',
                style: AppTextStyles.body(scale,
                    color: hc ? Colors.black87 : null),
              ),
              const SizedBox(height: 10),
              Text(
                '${_fmtUf(r.pensionMensualUf)} UF al mes',
                style: AppTextStyles.heading(scale * 0.9,
                    color: hc ? Colors.black : AppColors.tealDeep),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                      label: _esRp
                          ? 'Se recalcula cada año'
                          : 'Se reajusta con la UF',
                      color: accent),
                  if (r.cnuConyuge > 0)
                    AppChip(label: 'Incluye a tu cónyuge', color: accent),
                ],
              ),
              const SizedBox(height: 14),
              BotonEscuchar(
                highContrast: hc,
                texto: _esRp
                    ? 'Tu pensión mensual estimada para el primer año es de '
                        '${r.pensionMensualClp.round()} pesos. El monto se '
                        'recalcula cada año y puede subir o bajar. Es una '
                        'estimación educativa.'
                    : 'Tu pensión mensual estimada es de '
                        '${r.pensionMensualClp.round()} pesos, que son '
                        '${_fmtUf(r.pensionMensualUf)} UF. Se reajusta con '
                        'la UF y se paga de por vida. Es una estimación '
                        'educativa, no una oferta de una aseguradora.',
              ),
            ],
          ),
        ),
        if (_esRp) ...[
          const SizedBox(height: 12),
          InfoBanner(
            variant: BannerVariant.info,
            fontScale: scale,
            text: 'Es el monto del primer año. Cada año se recalcula según '
                'tu saldo y tu edad, y puede subir o bajar.',
          ),
        ],
        const SizedBox(height: 14),
        _buildGuardar(scale, hc),
        const SizedBox(height: 14),
        Plegable(
          titulo: 'Ver cómo se calculó',
          icono: Icons.receipt_long_outlined,
          color: accent,
          highContrast: hc,
          fontScale: scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dato('Saldo', '${_fmtClp(saldoClp)} (${_fmtUf(r.primaUf)} UF)',
                  scale, hc),
              _dato('Pensión en UF', '${_fmtUf(r.pensionMensualUf)} UF al mes',
                  scale, hc),
              _dato(
                'Valor de la UF',
                '${_fmtValorUf(r.valorUf)} al '
                    '${_fmtFecha(ParametrosVigentes.valorUfFecha)}',
                scale,
                hc,
              ),
              _dato(
                _esRp ? 'Tasa de Retiro Programado' : 'Tasa de referencia',
                _esRp && ParametrosVigentes.tasaRetiroProgramadoProvisoria
                    ? '$tasa % anual (provisoria)'
                    : '$tasa % anual',
                scale,
                hc,
              ),
              _dato('Mortalidad', 'Tablas oficiales TM2020', scale, hc),
              _dato(
                'Factor actuarial (CNU)',
                r.cnuTotal.toStringAsFixed(4).replaceAll('.', ','),
                scale,
                hc,
              ),
            ],
          ),
        ),
        const NotaTransparencia(),
      ],
    );
  }

  Widget _dato(String titulo, String valor, double scale, bool hc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : AppColors.inkSoft)),
          Text(valor,
              style: AppTextStyles.body(scale * 0.9,
                  color: hc ? Colors.black : null)),
        ],
      ),
    );
  }
}
