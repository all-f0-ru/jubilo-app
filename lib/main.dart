import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/main_tab_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/providers/comparativas_provider.dart';
import 'core/providers/simulaciones_provider.dart';
import 'core/providers/respuestas_encuesta_provider.dart';
import 'core/services/compras_service.dart';
import 'core/services/nube_service.dart';
import 'core/services/parametros_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'screens/onboarding_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conexión con Firebase (nunca detiene la app si falla).
  await NubeService.iniciar();
  // Tasas y UF: usa la última copia guardada y busca valores nuevos sin
  // hacer esperar a la persona.
  await ParametrosService.iniciar();
  // Premium: en Android se activa con una compra de Google Play.
  final premium = PremiumProvider();
  ComprasService.iniciar(premium);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MainTabProvider()),
        ChangeNotifierProvider.value(value: premium),
        ChangeNotifierProvider(create: (_) => SimulacionesProvider()),
        ChangeNotifierProvider(create: (_) => ComparativasProvider()),
        ChangeNotifierProvider(create: (_) => RespuestasEncuestaProvider()),
      ],
      child: const JubiloApp(),
    ),
  );
}

class JubiloApp extends StatelessWidget {
  const JubiloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;

    return MaterialApp(
      title: 'Jubilo',
      debugShowCheckedModeBanner: false,
      theme: settings.highContrast
          ? AppTheme.highContrast(scale)
          : AppTheme.light(scale),
      home: const SplashScreen(),
    );
  }
}
