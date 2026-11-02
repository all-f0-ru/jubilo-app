import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente_registro.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../services/registro_clientes_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'jubilo_widgets.dart';

/// Texto del precio del pago único. Pendiente de definir con el cliente.
const String precioPremiumTexto = 'Precio por definir';

/// Abre la pantalla que ofrece Premium (paso 1: beneficios, paso 2: datos
/// de la persona). Devuelve true si la persona lo desbloqueó (en modo
/// demostración, sin cobro).
Future<bool> mostrarPremiumSheet(BuildContext context) async {
  final resultado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const PremiumScreen(),
    ),
  );
  return resultado ?? false;
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();

  bool _paso2 = false;
  bool _acepta = false;
  bool _mostrarErrorAcepta = false;
  bool _guardando = false;
  String? _errorGuardar;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    final okForm = _form.currentState?.validate() ?? false;
    setState(() => _mostrarErrorAcepta = !_acepta);
    if (!okForm || !_acepta) return;

    setState(() {
      _guardando = true;
      _errorGuardar = null;
    });
    final premium = context.read<PremiumProvider>();
    final navigator = Navigator.of(context);
    try {
      // Primero el registro de la persona, después se activa Premium.
      await RegistroClientesService.registrar(ClienteRegistro(
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
        fecha: DateTime.now(),
      ));
      await premium.activarDemo();
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorGuardar =
            'No pudimos guardar tus datos. Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;
    final hc = settings.highContrast;
    final accent = hc ? Colors.black : AppColors.teal;
    final panel = hc ? Colors.black : AppColors.tealDeep;

    return PopScope(
      canPop: !_paso2,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso2) setState(() => _paso2 = false);
      },
      child: Scaffold(
        backgroundColor: hc ? Colors.white : AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: _paso2 ? 'Volver' : 'Cerrar',
                  icon: Icon(
                      _paso2 ? Icons.arrow_back_rounded : Icons.close_rounded,
                      color: hc ? Colors.black : AppColors.ink),
                  onPressed: () {
                    if (_paso2) {
                      setState(() => _paso2 = false);
                    } else {
                      Navigator.of(context).pop(false);
                    }
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _paso2
                      ? _buildDatos(scale, hc)
                      : _buildBeneficios(scale, hc, accent),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _paso2 ? _panelDatos(scale) : _panelOferta(scale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Paso 1: oferta ----------

  Widget _buildBeneficios(double scale, bool hc, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: IconBadge(
              icon: Icons.workspace_premium_rounded, color: accent, size: 72),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('Jubilo Premium',
              style: AppTextStyles.display(scale * 0.8,
                  color: hc ? Colors.black : null)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Un solo pago, sin suscripción',
              style: AppTextStyles.body(scale,
                  color: hc ? Colors.black54 : AppColors.inkSoft)),
        ),
        const SizedBox(height: 24),
        Text('Beneficios',
            style: AppTextStyles.heading(scale * 0.8,
                color: hc ? Colors.black : null)),
        const SizedBox(height: 14),
        _Beneficio(
          icono: Icons.bookmark_added_outlined,
          titulo: 'Guarda tus simulaciones',
          texto: 'Con el monto, la fecha y la hora en que las hiciste.',
          scale: scale,
          hc: hc,
        ),
        _Beneficio(
          icono: Icons.compare_arrows_rounded,
          titulo: 'Compara las modalidades',
          texto: 'Mira lado a lado Renta Vitalicia y Retiro Programado '
              'con tu saldo.',
          scale: scale,
          hc: hc,
        ),
        _Beneficio(
          icono: Icons.show_chart_rounded,
          titulo: 'Gráfica de tendencia',
          texto: 'Mira cómo cambian tus simulaciones guardadas.',
          scale: scale,
          hc: hc,
        ),
        const SizedBox(height: 4),
        InfoBanner(
          variant: BannerVariant.info,
          fontScale: scale,
          text: 'Modo demostración: no se realiza ningún cobro.',
        ),
      ],
    );
  }

  Widget _panelOferta(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Únete a Premium',
            style: AppTextStyles.heading(scale * 0.85, color: Colors.white)),
        const SizedBox(height: 2),
        Text('Pago único · $precioPremiumTexto',
            style: AppTextStyles.small(scale, color: Colors.white70)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.tealDeep,
            ),
            onPressed: () => setState(() => _paso2 = true),
            child: const Text('Quiero Premium'),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ahora no'),
        ),
      ],
    );
  }

  // ---------- Paso 2: datos ----------

  Widget _campo(String etiqueta, TextEditingController c, double scale,
      bool hc, String? Function(String?) validar,
      {TextInputType? tipo,
      Iterable<String>? autofill,
      TextCapitalization cap = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        textCapitalization: cap,
        autofillHints: autofill,
        validator: validar,
        style: AppTextStyles.body(scale, color: hc ? Colors.black : null),
        decoration: InputDecoration(labelText: etiqueta),
      ),
    );
  }

  Widget _buildDatos(double scale, bool hc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Antes de pagar, cuéntanos quién eres',
            style: AppTextStyles.heading(scale,
                color: hc ? Colors.black : null)),
        const SizedBox(height: 6),
        Text('Usaremos tus datos solo para gestionar tu compra.',
            style: AppTextStyles.small(scale,
                color: hc ? Colors.black54 : null)),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: Column(
            children: [
              _campo('Nombre completo', _nombre, scale, hc, validarNombre,
                  autofill: const [AutofillHints.name],
                  cap: TextCapitalization.words),
              _campo('Teléfono', _telefono, scale, hc, validarTelefono,
                  tipo: TextInputType.phone,
                  autofill: const [AutofillHints.telephoneNumber]),
              _campo('Correo electrónico', _correo, scale, hc, validarCorreo,
                  tipo: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email]),
            ],
          ),
        ),
        CheckboxListTile(
          value: _acepta,
          onChanged: (v) => setState(() {
            _acepta = v ?? false;
            _mostrarErrorAcepta = false;
          }),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Acepto que Jubilo guarde mis datos para gestionar mi compra.',
            style: AppTextStyles.small(scale,
                color: hc ? Colors.black87 : null),
          ),
        ),
        if (_mostrarErrorAcepta)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Debes aceptar para continuar.',
                style: AppTextStyles.small(scale, color: Colors.red[800])),
          ),
        if (_errorGuardar != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InfoBanner(
              variant: BannerVariant.warning,
              fontScale: scale,
              text: _errorGuardar!,
            ),
          ),
      ],
    );
  }

  Widget _panelDatos(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pago único · $precioPremiumTexto',
            style: AppTextStyles.small(scale, color: Colors.white70)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.tealDeep,
            ),
            onPressed: _guardando ? null : _pagar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Desbloquear Premium'),
          ),
        ),
      ],
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final double scale;
  final bool hc;

  const _Beneficio({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.scale,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    final color = hc ? Colors.black : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icono, color: color, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTextStyles.heading(scale * 0.72,
                        color: hc ? Colors.black : null)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTextStyles.small(scale,
                        color: hc ? Colors.black54 : null)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
