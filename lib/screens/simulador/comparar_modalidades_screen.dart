import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/pension_engine/cnu_engine.dart';
import '../../core/pension_engine/modalidades_mixtas.dart';
import '../../core/pension_engine/pension_config.dart';
import '../../core/pension_engine/renta_vitalicia.dart';
import '../../core/pension_engine/retiro_programado.dart';
import '../../core/pension_engine/tm2020_assets.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/respuestas_encuesta_provider.dart';
import '../../core/providers/simulaciones_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/models/comparativa_guardada.dart';
import '../../core/models/simulacion_guardada.dart';
import '../../core/providers/comparativas_provider.dart';
import '../../core/widgets/hijos_selector.dart';
import '../../core/widgets/premium_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';
import '../../core/widgets/nota_transparencia.dart';
import '../modalidades/modalidad_detail_screen.dart';

/// Respuestas de partida cuando la persona entra sin haber hecho la encuesta
/// (por ejemplo, desde la pestaña Modalidades): usa lo que ya contó en
/// Ajustes y parte como soltero/a sin hijos.
SimuladorRespuestas respuestasPorDefecto(SettingsProvider settings) {
  final edad = settings.edad;
  final String rango;
  if (edad == null) {
    rango = '61 a 64';
  } else if (edad <= 55) {
    rango = '55 o menos';
  } else if (edad <= 60) {
    rango = '56 a 60';
  } else if (edad <= 64) {
    rango = '61 a 64';
  } else {
    rango = '65 o más';
  }
  return SimuladorRespuestas(
    rangoEdad: rango,
    sexo: settings.sexo ?? 'Mujer',
    estadoCivil: 'Soltero/a',
    tieneHijos: false,
  );
}

String _puntos(String digitos) {
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

String _clp(double v) => '\$${_puntos(v.round().toString())}';

int _limitar(int valor, int minimo, int maximo) {
  if (valor < minimo) return minimo;
  if (valor > maximo) return maximo;
  return valor;
}

/// Mientras la persona escribe el saldo, le va poniendo los puntos de miles.
class _FormatoMiles extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue(text: '');
    if (digitos.length > 12) digitos = digitos.substring(0, 12);
    final texto = _puntos(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Compara, con el mismo saldo, la pensión de la Renta Vitalicia Inmediata y
/// la del Retiro Programado. Cada una usa su propio algoritmo.
///
/// Es una referencia educativa: no es una oferta de una aseguradora ni el
/// cálculo oficial de una AFP.
class CompararModalidadesScreen extends StatefulWidget {
  final SimuladorRespuestas respuestas;

  const CompararModalidadesScreen({super.key, required this.respuestas});

  @override
  State<CompararModalidadesScreen> createState() =>
      _CompararModalidadesScreenState();
}

class _CompararModalidadesScreenState extends State<CompararModalidadesScreen> {
  static const List<int> _saldosRapidosMillones = [10, 20, 30, 50];

  final TextEditingController _saldoCtrl = TextEditingController();

  int _edad = 65;
  int _edadConyuge = 62;
  String? _conyugeSexo; // 'F' | 'M'

  Map<String, MortalityTable>? _tablas;
  String? _errorCarga;

  ResultadoRentaVitalicia? _rvi;
  ResultadoRetiroProgramado? _rp;
  String? _errorCalculo;

  // Modalidades combinadas (solo hasta los 65 años) y sus ajustes.
  ResultadoTemporalVitalicia? _temporal;
  ResultadoRvRp? _rvRp;
  int _aniosCotizados = 25;
  int _pctRv = 50;
  int _aniosTemporal = 2;
  int _relacionPct = 150;
  List<int> _hijos = [];

  // Aportes del Estado (PGU y BAC) de las dos modalidades oficiales.
  double _pguRvi = 0, _bacRvi = 0, _pguRp = 0, _bacRp = 0;

  bool get _conHijos => widget.respuestas.tieneHijos;

  bool get _conConyuge => widget.respuestas.estadoCivil == 'Casado/a';

  int? get _saldo => int.tryParse(_saldoCtrl.text.replaceAll('.', ''));

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();
    final recordados = context.read<RespuestasEncuestaProvider>();
    _edad = recordados.edad != null
        ? _limitar(recordados.edad!, 50, 100)
        : _edadInicial(settings);
    _edadConyuge = _limitar(_edad, 18, 100);
    if (recordados.saldoClp != null) {
      _saldoCtrl.text = _puntos('${recordados.saldoClp}');
    }
    if (recordados.aniosCotizados != null) {
      _aniosCotizados = _limitar(recordados.aniosCotizados!, 0, 45);
    }
    _pctRv = recordados.extraInt('pctRv') ?? _pctRv;
    _aniosTemporal =
        _limitar(recordados.extraInt('aniosTemporal') ?? _aniosTemporal, 1, 5);
    _relacionPct = recordados.extraInt('relacionPct') ?? _relacionPct;
    final sexoC = recordados.extraTexto('conyugeSexo');
    if (sexoC == 'F' || sexoC == 'M') _conyugeSexo = sexoC;
    final edadC = recordados.extraInt('conyugeEdad');
    if (edadC != null) _edadConyuge = _limitar(edadC, 18, 100);
    if (_conHijos) {
      _hijos = recordados
          .extraListaInt('hijosEdades')
          .where((h) => h >= 0 && h <= edadMaximaHijo)
          .take(maximoHijos)
          .toList();
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
    super.dispose();
  }

  int _edadInicial(SettingsProvider settings) {
    final guardada = settings.edad;
    if (guardada != null && settings.sexo == widget.respuestas.sexo) {
      return _limitar(guardada, 50, 100);
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

  void _actualizar(VoidCallback cambio) {
    setState(() {
      cambio();
      _calcular();
    });
    context.read<RespuestasEncuestaProvider>().recordarDatos(
        saldoClp: _saldo, edad: _edad, aniosCotizados: _aniosCotizados);
    context.read<RespuestasEncuestaProvider>().recordarExtras({
      'pctRv': _pctRv,
      'aniosTemporal': _aniosTemporal,
      'relacionPct': _relacionPct,
      'hijosEdades': _hijos,
      'conyugeSexo': ?_conyugeSexo,
      'conyugeEdad': _edadConyuge,
    });
  }

  DateTime _nacimientoParaEdad(DateTime hoy, int edad) {
    var dia = hoy.day;
    if (hoy.month == 2 && dia == 29) dia = 28;
    return DateTime(hoy.year - edad, hoy.month, dia);
  }

  String _codigoSexo(String sexo) => sexo == 'Mujer' ? 'F' : 'M';

  /// Calcula las dos modalidades con los datos actuales. No llama a
  /// setState: se usa siempre desde dentro de uno.
  void _calcular() {
    _rvi = null;
    _rp = null;
    _temporal = null;
    _rvRp = null;
    _errorCalculo = null;
    _pguRvi = _bacRvi = _pguRp = _bacRp = 0;

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
      _rvi = calcularRentaVitalicia(
        primaUf: saldoUf,
        grupoFamiliar: grupo,
        parametros: ParametrosRvi(
          fechaReferencia: hoy,
          tasaReferencia: ParametrosVigentes.tasaReferencia,
        ),
        valorUf: ParametrosVigentes.valorUf,
        tablas: tablas,
      );
      final pguParams = parametrosPguBacActual;
      final bacUf = calcularBacUf(_aniosCotizados.toDouble(),
          minimoAniosBac(widget.respuestas.sexo), pguParams);
      _bacRvi = bacUf * ParametrosVigentes.valorUf;
      _bacRp = _bacRvi;
      _pguRvi = calcularPgu(_rvi!.pensionMensualClp, pguParams);
      _rp = calcularRetiroProgramado(
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
      _pguRp = calcularPgu(_rp!.pensionMensualClp, pguParams);

      // Las dos modalidades combinadas usan la mortalidad aproximada del
      // cliente y solo están pensadas para pensionarse hasta los 65 años.
      if (_edad <= 65) {
        final minimo = minimoAniosBac(widget.respuestas.sexo);
        try {
          _temporal = simularRentaTemporalVitalicia(
            saldoClp: saldoClp.toDouble(),
            edad: _edad,
            aniosTemporal: _aniosTemporal,
            relacion: _relacionPct / 100,
            tasa: ParametrosVigentes.tasaReferenciaVejez,
            valorUf: ParametrosVigentes.valorUf,
            aniosCotizados: _aniosCotizados.toDouble(),
            minimoAnios: minimo,
            hijosEdades: _conHijos ? _hijos : const [],
            pgu: pguParams,
          );
          _rvRp = simularRvInmediataConRp(
            saldoClp: saldoClp.toDouble(),
            edad: _edad,
            pctRv: _pctRv / 100,
            tasaRv: ParametrosVigentes.tasaReferenciaVejez,
            tasaRp: ParametrosVigentes.tasaRetiroProgramado,
            rentabilidad: ParametrosVigentes.rentabilidadReal,
            valorUf: ParametrosVigentes.valorUf,
            aniosCotizados: _aniosCotizados.toDouble(),
            minimoAnios: minimo,
            hijosEdades: _conHijos ? _hijos : const [],
            pgu: pguParams,
          );
        } on ModalidadesMixtasException {
          _temporal = null;
          _rvRp = null;
        }
      }
    } on CNUException catch (e) {
      _rvi = null;
      _rp = null;
      _errorCalculo = e.message;
    } on RentaVitaliciaException catch (e) {
      _rvi = null;
      _rp = null;
      _errorCalculo = e.message;
    } on RetiroProgramadoException catch (e) {
      _rvi = null;
      _rp = null;
      _errorCalculo = e.message;
    }
  }

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

  ModalidadInfo _info(String id) =>
      modalidadesPension.firstWhere((m) => m.id == id);

  void _abrirDetalle(String id) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      JubiloPageRoute(
        builder: (_) => ModalidadDetailScreen(
          modalidad: _info(id),
          respuestas: widget.respuestas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final reducir = reduceMotion(context);

    // La comparativa completa es Premium: sin pago no se muestra nada más.
    if (!context.watch<PremiumProvider>().esPremium) {
      return Scaffold(
        backgroundColor: hc ? Colors.white : AppColors.cream,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Comparar modalidades',
              style:
                  AppTextStyles.heading(0.8, color: hc ? Colors.black : null)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [_BloqueoPremium(scale: scale, hc: hc)],
          ),
        ),
      );
    }

    final String estado;
    if (_errorCarga != null) {
      estado = 'error-carga';
    } else if (_tablas == null) {
      estado = 'carga';
    } else if (_errorCalculo != null) {
      estado = 'error-calculo';
    } else if (_rvi == null || _rp == null) {
      estado = 'vacio';
    } else {
      estado = 'resultado';
    }

    return Scaffold(
      backgroundColor: hc ? Colors.white : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Comparar modalidades',
            style: AppTextStyles.heading(0.8, color: hc ? Colors.black : null)),
      ),
      body: SafeArea(
        child: ListView(
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
              inputFormatters: [_FormatoMiles()],
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
            _titulo('Años cotizados', scale, hc),
            StepperNumero(
              valor: _aniosCotizados,
              minimo: 0,
              maximo: 45,
              sufijo: 'años',
              highContrast: hc,
              fontScale: scale,
              onChanged: (v) => _actualizar(() => _aniosCotizados = v),
            ),
            const SizedBox(height: 6),
            Text(
              'Con ${minimoAniosBac(widget.respuestas.sexo)} años o más '
              'cotizados se suma el Bono por Años Cotizados (BAC) desde los '
              '65 años, y la PGU según tu pensión.',
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : null),
            ),

            if (_conHijos) ...[
              const SizedBox(height: 28),
              _titulo('Tus hijos/as', scale, hc),
              HijosSelector(
                edades: _hijos,
                scale: scale,
                altoContraste: hc,
                onChanged: (v) => _actualizar(() => _hijos = v),
              ),
            ],

            if (_edad <= 65) ...[
              const SizedBox(height: 28),
              Plegable(
                titulo: 'Ajustes de las modalidades combinadas',
                icono: Icons.tune_rounded,
                color: hc ? Colors.black : AppColors.teal,
                highContrast: hc,
                fontScale: scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parte a Renta Vitalicia (con Retiro Programado)',
                        style: AppTextStyles.body(scale,
                            color: hc ? Colors.black : null)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final p in const [30, 50, 70])
                        _chipOpcion('$p%', _pctRv == p,
                            () => _actualizar(() => _pctRv = p), scale, hc),
                    ]),
                    const SizedBox(height: 18),
                    Text('Años de Renta Temporal',
                        style: AppTextStyles.body(scale,
                            color: hc ? Colors.black : null)),
                    const SizedBox(height: 8),
                    StepperNumero(
                      valor: _aniosTemporal,
                      minimo: 1,
                      maximo: 5,
                      sufijo: _aniosTemporal == 1 ? 'año' : 'años',
                      highContrast: hc,
                      fontScale: scale,
                      onChanged: (v) => _actualizar(() => _aniosTemporal = v),
                    ),
                    const SizedBox(height: 18),
                    Text('Renta temporal comparada con la vitalicia',
                        style: AppTextStyles.body(scale,
                            color: hc ? Colors.black : null)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final p in const [100, 150, 200])
                        _chipOpcion('$p%', _relacionPct == p,
                            () => _actualizar(() => _relacionPct = p), scale, hc),
                    ]),
                  ],
                ),
              ),
            ],

            if (_conHijos) ...[
              const SizedBox(height: 24),
              InfoBanner(
                variant: BannerVariant.info,
                fontScale: scale,
                text: 'Tus hijos/as se consideran en las dos modalidades '
                    'combinadas (aproximación referencial). En Renta '
                    'Vitalicia y Retiro Programado todavía no.',
              ),
            ],

            const SizedBox(height: 28),
            Text(
              'Estimación educativa. No es una oferta de una aseguradora ni '
              'el cálculo oficial de una AFP.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.small(scale, color: hc ? Colors.black54 : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipOpcion(
      String label, bool sel, VoidCallback onTap, double scale, bool hc) {
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
        _saldoCtrl.text = _puntos('${millones * 1000000}');
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
        return _buildResultados(_rvi!, _rp!, scale, hc);
      default:
        return JubiloCard(
          child: Row(
            children: [
              IconBadge(icon: Icons.compare_arrows_rounded, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _conConyuge && _conyugeSexo == null
                      ? 'Escribe tu saldo y elige el sexo de tu cónyuge'
                      : 'Escribe tu saldo para comparar',
                  style: AppTextStyles.body(scale,
                      color: hc ? Colors.black87 : null),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Fila de la modalidad Vitalicia + Retiro Programado a los 65 años.
  FilaRvRp? _filaA65() {
    final r = _rvRp;
    if (r == null) return null;
    for (final f in r.filas) {
      if (f.edad == 65) return f;
    }
    return null;
  }

  double _pguRvRp() => _filaA65()?.pguClp ?? 0;
  double _bacRvRp() => _filaA65()?.bacClp ?? 0;
  /// Guarda lo que hoy se ve en pantalla (Premium) para verlo después en
  /// "Mis simulaciones".
  Future<void> _guardarComparativa() async {
    final rvi = _rvi;
    final rp = _rp;
    final saldo = _saldo;
    if (rvi == null || rp == null || saldo == null) return;
    final comparativas = context.read<ComparativasProvider>();
    final mensajes = ScaffoldMessenger.of(context);
    // Si ya guardó una hoy, avisamos y guardamos solo si está de acuerdo.
    if (comparativas.hayGuardadaHoy) {
      final acepta = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ya guardaste una comparativa hoy'),
          content: const Text(
              'Hoy ya hay una versión guardada. ¿Quieres guardar esta '
              'como una versión nueva del día?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No, cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sí, guardar'),
            ),
          ],
        ),
      );
      if (acepta != true || !mounted) return;
    }
    final ahora = DateTime.now();
    final f = _filaA65();
    final simsHechas = context.read<SimulacionesProvider>().todas;
    bool hecha(String m) => simsHechas.any((x) => x.modalidad == m);
    final c = ComparativaGuardada(
      id: ahora.microsecondsSinceEpoch.toString(),
      fecha: ahora,
      saldoClp: saldo,
      edad: _edad,
      sexo: widget.respuestas.sexo,
      aniosCotizados: _aniosCotizados,
      conConyuge: _conConyuge,
      cantidadHijos: _conHijos ? _hijos.length : 0,
      valorUf: ParametrosVigentes.valorUf,
      filas: [
        if (hecha(SimulacionGuardada.rentaVitalicia))
        FilaComparativa(
          modalidad: SimulacionGuardada.rentaVitalicia,
          montoClp: rvi.pensionMensualClp,
          montoUf: rvi.pensionMensualUf,
          pguClp: _pguRvi,
          bacClp: _bacRvi,
        ),
        if (hecha(SimulacionGuardada.retiroProgramado))
        FilaComparativa(
          modalidad: SimulacionGuardada.retiroProgramado,
          montoClp: rp.pensionMensualClp,
          montoUf: rp.pensionMensualUf,
          pguClp: _pguRp,
          bacClp: _bacRp,
        ),
        if (_temporal != null && _rvRp != null) ...[
          if (hecha(SimulacionGuardada.temporalVitalicia))
          FilaComparativa(
            modalidad: SimulacionGuardada.temporalVitalicia,
            montoClp: _temporal!.temporalClp,
            montoUf: _temporal!.temporalUf,
            pguClp: _temporal!.pguClp,
            bacClp: _temporal!.bacClp,
          ),
          if (hecha(SimulacionGuardada.rvConRp))
          FilaComparativa(
            modalidad: SimulacionGuardada.rvConRp,
            montoClp: _rvRp!.filas.first.rvClp + _rvRp!.filas.first.rpClp,
            montoUf: _rvRp!.filas.first.rvUf + _rvRp!.filas.first.rpUf,
            pguClp: f?.pguClp ?? 0,
            bacClp: f?.bacClp ?? 0,
          ),
        ],
      ],
    );
    await comparativas.guardar(c);
    mensajes.showSnackBar(const SnackBar(
        content: Text('Comparativa guardada. La ves en Mis simulaciones.')));
  }

  Widget _buildResultados(
    ResultadoRentaVitalicia rvi,
    ResultadoRetiroProgramado rp,
    double scale,
    bool hc,
  ) {
    final infoRvi = _info('renta_vitalicia_inmediata');
    final infoRp = _info('retiro_programado');
    // Solo se muestran las modalidades que la persona ya simuló y guardó.
    final sims = context.watch<SimulacionesProvider>().todas;
    bool hecha(String m) => sims.any((x) => x.modalidad == m);
    final hechaRvi = hecha(SimulacionGuardada.rentaVitalicia);
    final hechaRp = hecha(SimulacionGuardada.retiroProgramado);
    final hechaTemp = hecha(SimulacionGuardada.temporalVitalicia);
    final hechaRvRp = hecha(SimulacionGuardada.rvConRp);
    final diferencia = rvi.pensionMensualClp - rp.pensionMensualClp;

    // Siempre se nombran los dos montos (los mismos de las tarjetas de
    // arriba) y la diferencia aparte, para que no se confunda con un monto.
    final montos = 'Renta Vitalicia: ${_clp(rvi.pensionMensualClp)} al mes. '
        'Retiro Programado: ${_clp(rp.pensionMensualClp)} al mes el primer '
        'año.';
    final String resumen;
    if (diferencia.abs() < 1000) {
      resumen = '$montos Con tu saldo, las dos dan un monto parecido.';
    } else if (diferencia > 0) {
      resumen = '$montos La diferencia: la Renta Vitalicia da '
          '${_clp(diferencia)} más al mes el primer año.';
    } else {
      resumen = '$montos La diferencia: el Retiro Programado da '
          '${_clp(-diferencia)} más al mes el primer año.';
    }

    final filas = <_FilaResumen>[
      if (hechaRvi)
        _FilaResumen('Renta Vitalicia', hc ? Colors.black : infoRvi.color,
            rvi.pensionMensualClp),
      if (hechaRp)
        _FilaResumen('Retiro Programado', hc ? Colors.black : infoRp.color,
            rp.pensionMensualClp),
      if (_temporal != null && _rvRp != null) ...[
        if (hechaTemp)
        _FilaResumen(
            'Temporal + Vitalicia Diferida',
            hc
                ? Colors.black
                : _info('renta_temporal_vitalicia_diferida').color,
            _temporal!.temporalClp),
        if (hechaRvRp)
        _FilaResumen(
            'Vitalicia + Retiro Programado',
            hc
                ? Colors.black
                : _info('renta_vitalicia_con_retiro_programado').color,
            _rvRp!.filas.first.rvClp + _rvRp!.filas.first.rpClp),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filas.isEmpty)
          InfoBanner(
            variant: BannerVariant.info,
            fontScale: scale,
            text: 'Aún no has simulado ni guardado ninguna modalidad. '
                'Simula una y guárdala: aparecerá aquí para compararla.',
          )
        else if (filas.length == 1)
          InfoBanner(
            variant: BannerVariant.info,
            fontScale: scale,
            text: 'Para comparar, simula y guarda al menos otra modalidad.',
          )
        else
          _ResumenComparacion(filas: filas, scale: scale, hc: hc),
        const SizedBox(height: 20),
        if (!hechaRvi)
          _TarjetaPendiente(
            nombre: 'Renta Vitalicia',
            icono: infoRvi.icono,
            color: hc ? Colors.black : infoRvi.color,
            scale: scale,
            hc: hc,
            onTap: () => _abrirDetalle('renta_vitalicia_inmediata'),
          )
        else
        _TarjetaModalidad(
          nombre: 'Renta Vitalicia',
          icono: infoRvi.icono,
          color: hc ? Colors.black : infoRvi.color,
          monto: rvi.pensionMensualClp,
          montoUf: rvi.pensionMensualUf,
          bajada: 'al mes, de por vida',
          chips: const ['Monto fijo en UF', 'No cambia'],
          aviso: rvi.cumpleUmbralMinimo
              ? null
              : 'Con este saldo queda bajo el mínimo para contratarla.',
          muted: !rvi.cumpleUmbralMinimo,
          pgu: _pguRvi,
          bac: _bacRvi,
          scale: scale,
          hc: hc,
          onTap: () => _abrirDetalle('renta_vitalicia_inmediata'),
        ),
        const SizedBox(height: 12),
        if (!hechaRp)
          _TarjetaPendiente(
            nombre: 'Retiro Programado',
            icono: infoRp.icono,
            color: hc ? Colors.black : infoRp.color,
            scale: scale,
            hc: hc,
            onTap: () => _abrirDetalle('retiro_programado'),
          )
        else
        _TarjetaModalidad(
          nombre: 'Retiro Programado',
          icono: infoRp.icono,
          color: hc ? Colors.black : infoRp.color,
          monto: rp.pensionMensualClp,
          montoUf: rp.pensionMensualUf,
          bajada: 'al mes, el primer año',
          chips: const ['Se recalcula cada año', 'Puede subir o bajar'],
          aviso: ParametrosVigentes.tasaRetiroProgramadoProvisoria
              ? 'Tasa provisoria, por confirmar.'
              : null,
          muted: false,
          pgu: _pguRp,
          bac: _bacRp,
          scale: scale,
          hc: hc,
          onTap: () => _abrirDetalle('retiro_programado'),
        ),
        if (_temporal != null && _rvRp != null) ...[
          const SizedBox(height: 12),
          if (!hechaTemp)
            _TarjetaPendiente(
              nombre: 'Renta Temporal + Vitalicia Diferida',
              icono: _info('renta_temporal_vitalicia_diferida').icono,
              color: hc
                  ? Colors.black
                  : _info('renta_temporal_vitalicia_diferida').color,
              scale: scale,
              hc: hc,
              onTap: () => _abrirDetalle('renta_temporal_vitalicia_diferida'),
            )
          else
          _TarjetaModalidad(
            nombre: 'Renta Temporal + Vitalicia Diferida',
            icono: _info('renta_temporal_vitalicia_diferida').icono,
            color: hc
                ? Colors.black
                : _info('renta_temporal_vitalicia_diferida').color,
            monto: _temporal!.temporalClp,
            montoUf: _temporal!.temporalUf,
            bajada: 'al mes, durante ${_temporal!.aniosTemporal} '
                '${_temporal!.aniosTemporal == 1 ? 'año' : 'años'}',
            chips: [
              'Después: ${_clp(_temporal!.vitalicioClp)} al mes',
              'Vitalicia fija en UF',
            ],
            aviso: 'Luego, desde los ${_temporal!.edadInicioVitalicia} años, '
                'de por vida. No incluye cónyuge.',
            muted: false,
            pguEtiqueta: 'Desde los ${_temporal!.edadInicioVitalicia} años, '
                'con la vitalicia',
            pgu: _temporal!.pguClp,
            bac: _temporal!.bacClp,
            scale: scale,
            hc: hc,
            onTap: () => _abrirDetalle('renta_temporal_vitalicia_diferida'),
          ),
          const SizedBox(height: 12),
          if (!hechaRvRp)
            _TarjetaPendiente(
              nombre: 'Renta Vitalicia + Retiro Programado',
              icono: _info('renta_vitalicia_con_retiro_programado').icono,
              color: hc
                  ? Colors.black
                  : _info('renta_vitalicia_con_retiro_programado').color,
              scale: scale,
              hc: hc,
              onTap: () =>
                  _abrirDetalle('renta_vitalicia_con_retiro_programado'),
            )
          else
          _TarjetaModalidad(
            nombre: 'Renta Vitalicia + Retiro Programado',
            icono: _info('renta_vitalicia_con_retiro_programado').icono,
            color: hc
                ? Colors.black
                : _info('renta_vitalicia_con_retiro_programado').color,
            monto: _rvRp!.filas.first.rvClp + _rvRp!.filas.first.rpClp,
            montoUf: _rvRp!.filas.first.rvUf + _rvRp!.filas.first.rpUf,
            bajada: 'al mes, al pensionarte',
            chips: [
              '$_pctRv% renta vitalicia',
              '${100 - _pctRv}% retiro programado',
            ],
            aviso: 'La parte de retiro programado se recalcula cada año. '
                'No incluye cónyuge.',
            muted: false,
            pgu: _pguRvRp(),
            bac: _bacRvRp(),
            scale: scale,
            hc: hc,
            onTap: () => _abrirDetalle('renta_vitalicia_con_retiro_programado'),
          ),
        ] else if (_edad > 65) ...[
          const SizedBox(height: 12),
          InfoBanner(
            variant: BannerVariant.info,
            fontScale: scale,
            text: 'Las modalidades combinadas (Renta Temporal + Vitalicia '
                'Diferida y Renta Vitalicia + Retiro Programado) se '
                'comparan hasta los 65 años.',
          ),
        ],
        if (hechaRvi && hechaRp) ...[
          const SizedBox(height: 12),
          InfoBanner(
            variant: BannerVariant.info,
            fontScale: scale,
            text: '$resumen No son lo mismo: la Renta Vitalicia es fija y '
                'dura toda la vida; el Retiro Programado cambia cada año.',
          ),
        ],
        if (filas.length >= 2) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardarComparativa,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Guardar esta comparativa'),
            ),
          ),
        ],
        const NotaTransparencia(),
      ],
    );
  }
}

/// Se muestra en lugar de la comparativa cuando la persona no tiene Premium.
class _BloqueoPremium extends StatelessWidget {
  final double scale;
  final bool hc;

  const _BloqueoPremium({required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    return JubiloCard(
      borderColor: accent,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.lock_outline_rounded, color: accent, size: 48),
          const SizedBox(height: 14),
          Text('Comparar modalidades es Premium',
              style: AppTextStyles.heading(scale * 0.85,
                  color: hc ? Colors.black : null)),
          const SizedBox(height: 8),
          Text(
            'Mira lado a lado cuánto recibirías con cada modalidad de '
            'pensión, con tu mismo saldo.',
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

/// Modalidad que la persona todavía no ha simulado: invita a simularla.
class _TarjetaPendiente extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final Color color;
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _TarjetaPendiente({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.scale,
    required this.hc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JubiloCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icono, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: AppTextStyles.body(scale,
                            color: hc ? Colors.black : null)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Aún no la has simulado. Toca para simularla y '
                    'guardarla.',
                    style: AppTextStyles.small(scale,
                        color: hc ? Colors.black54 : AppColors.inkSoft)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: hc ? Colors.black : AppColors.inkSoft),
        ],
      ),
    );
  }
}

class _TarjetaModalidad extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final Color color;
  final double monto;
  final double montoUf;
  final String bajada;
  final List<String> chips;
  final String? aviso;
  final bool muted;
  final double pgu;
  final double bac;
  final String pguEtiqueta;
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _TarjetaModalidad({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.monto,
    required this.montoUf,
    required this.bajada,
    required this.chips,
    required this.aviso,
    required this.muted,
    this.pgu = 0,
    this.bac = 0,
    this.pguEtiqueta = 'Desde los 65 años',
    required this.scale,
    required this.hc,
    required this.onTap,
  });

  Widget _filaAporte(String k, double v, {bool destacado = false}) {
    final estilo = destacado
        ? AppTextStyles.body(scale, color: hc ? Colors.black : null)
            .copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.small(scale, color: hc ? Colors.black87 : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k, style: estilo)),
          Text(_clp(v), style: estilo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tonoMonto = muted
        ? (hc ? Colors.black54 : AppColors.inkSoft)
        : (hc ? Colors.black : color);

    return JubiloCard(
      onTap: onTap,
      borderColor: color,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icono, color: color, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(nombre,
                    style: AppTextStyles.heading(scale * 0.8,
                            color: hc ? Colors.black : null)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: hc ? Colors.black : AppColors.inkSoft),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_clp(monto),
                style: AppTextStyles.display(scale, color: tonoMonto)),
          ),
          Text(bajada,
              style: AppTextStyles.body(scale,
                  color: hc ? Colors.black87 : null)),
          const SizedBox(height: 6),
          Text('${montoUf.toStringAsFixed(2).replaceAll('.', ',')} UF al mes',
              style: AppTextStyles.heading(scale * 0.8,
                  color: hc ? Colors.black : AppColors.tealDeep)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips) AppChip(label: c, color: color),
            ],
          ),
          if (pgu > 0 || bac > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (hc ? Colors.black : AppColors.teal)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aportes del Estado · $pguEtiqueta',
                      style: AppTextStyles.small(scale,
                              color: hc ? Colors.black : AppColors.tealDeep)
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  if (pgu > 0) _filaAporte('PGU', pgu),
                  if (bac > 0) _filaAporte('BAC', bac),
                  const SizedBox(height: 4),
                  _filaAporte('Total estimado al mes', monto + pgu + bac,
                      destacado: true),
                ],
              ),
            ),
          ],
          if (aviso != null) ...[
            const SizedBox(height: 10),
            Text(aviso!,
                style: AppTextStyles.small(scale,
                    color: hc ? Colors.black54 : null)),
          ],
        ],
      ),
    );
  }
}

class _FilaResumen {
  final String nombre;
  final Color color;
  final double monto;
  const _FilaResumen(this.nombre, this.color, this.monto);
}

/// Encabezado de la comparativa: barras para ver de un vistazo cuánto da
/// cada modalidad al mes al pensionarte.
class _ResumenComparacion extends StatelessWidget {
  final List<_FilaResumen> filas;
  final double scale;
  final bool hc;

  const _ResumenComparacion(
      {required this.filas, required this.scale, required this.hc});

  @override
  Widget build(BuildContext context) {
    final accent = hc ? Colors.black : AppColors.teal;
    final maximo = filas.fold<double>(0, (m, f) => f.monto > m ? f.monto : m);
    final mejor = filas.isEmpty
        ? null
        : filas.reduce((a, b) => b.monto > a.monto ? b : a);

    return JubiloCard(
      borderColor: accent,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.bar_chart_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Así se comparan',
                    style: AppTextStyles.heading(scale * 0.85,
                        color: hc ? Colors.black : null)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pensión mensual al pensionarte, sin aportes del Estado.',
              style: AppTextStyles.small(scale,
                  color: hc ? Colors.black54 : null)),
          const SizedBox(height: 14),
          for (final f in filas) ...[
            Row(
              children: [
                Expanded(
                  child: Text(f.nombre,
                      style: AppTextStyles.small(scale,
                              color: hc ? Colors.black : null)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(_clp(f.monto),
                    style: AppTextStyles.small(scale,
                            color: hc ? Colors.black : null)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maximo <= 0 ? 0 : (f.monto / maximo).clamp(0.0, 1.0),
                minHeight: 10,
                color: f.color,
                backgroundColor: AppColors.creamDeep,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (mejor != null && filas.length > 1)
            Text('Mayor monto al mes: ${mejor.nombre}.',
                style: AppTextStyles.small(scale,
                        color: hc ? Colors.black : AppColors.tealDeep)
                    .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
