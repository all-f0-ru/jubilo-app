import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/pension_engine/cnu_engine.dart';
import '../../core/pension_engine/pension_config.dart';
import '../../core/pension_engine/renta_vitalicia.dart';
import '../../core/pension_engine/retiro_programado.dart';
import '../../core/pension_engine/tm2020_assets.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/simulador_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/jubilo_motion.dart';
import '../../core/widgets/jubilo_widgets.dart';
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

  bool get _conConyuge => widget.respuestas.estadoCivil == 'Casado/a';

  int? get _saldo => int.tryParse(_saldoCtrl.text.replaceAll('.', ''));

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();
    _edad = _edadInicial(settings);
    _edadConyuge = _limitar(_edad, 18, 100);

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

  Widget _buildResultados(
    ResultadoRentaVitalicia rvi,
    ResultadoRetiroProgramado rp,
    double scale,
    bool hc,
  ) {
    final infoRvi = _info('renta_vitalicia_inmediata');
    final infoRp = _info('retiro_programado');
    final diferencia = rvi.pensionMensualClp - rp.pensionMensualClp;

    final String resumen;
    if (diferencia.abs() < 1000) {
      resumen = 'Con tu saldo, las dos dan un monto parecido el primer año.';
    } else if (diferencia > 0) {
      resumen = 'Con tu saldo, la Renta Vitalicia da ${_clp(diferencia)} '
          'más al mes que el Retiro Programado el primer año.';
    } else {
      resumen = 'Con tu saldo, el Retiro Programado da '
          '${_clp(-diferencia)} más al mes que la Renta Vitalicia el '
          'primer año.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TarjetaModalidad(
          nombre: 'Renta Vitalicia',
          icono: infoRvi.icono,
          color: hc ? Colors.black : infoRvi.color,
          monto: rvi.pensionMensualClp,
          bajada: 'al mes, de por vida',
          chips: const ['Monto fijo en UF', 'No cambia'],
          aviso: rvi.cumpleUmbralMinimo
              ? null
              : 'Con este saldo queda bajo el mínimo para contratarla.',
          muted: !rvi.cumpleUmbralMinimo,
          scale: scale,
          hc: hc,
          onTap: () => _abrirDetalle('renta_vitalicia_inmediata'),
        ),
        const SizedBox(height: 12),
        _TarjetaModalidad(
          nombre: 'Retiro Programado',
          icono: infoRp.icono,
          color: hc ? Colors.black : infoRp.color,
          monto: rp.pensionMensualClp,
          bajada: 'al mes, el primer año',
          chips: const ['Se recalcula cada año', 'Puede subir o bajar'],
          aviso: ParametrosVigentes.tasaRetiroProgramadoProvisoria
              ? 'Tasa provisoria, por confirmar.'
              : null,
          muted: false,
          scale: scale,
          hc: hc,
          onTap: () => _abrirDetalle('retiro_programado'),
        ),
        const SizedBox(height: 12),
        InfoBanner(
          variant: BannerVariant.info,
          fontScale: scale,
          text: '$resumen No son lo mismo: la Renta Vitalicia es fija y '
              'dura toda la vida; el Retiro Programado cambia cada año.',
        ),
      ],
    );
  }
}

class _TarjetaModalidad extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final Color color;
  final double monto;
  final String bajada;
  final List<String> chips;
  final String? aviso;
  final bool muted;
  final double scale;
  final bool hc;
  final VoidCallback onTap;

  const _TarjetaModalidad({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.monto,
    required this.bajada,
    required this.chips,
    required this.aviso,
    required this.muted,
    required this.scale,
    required this.hc,
    required this.onTap,
  });

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
                        color: hc ? Colors.black : null)),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips) AppChip(label: c, color: color),
            ],
          ),
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
