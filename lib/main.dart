import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/main_tab_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/providers/simulaciones_provider.dart';
import 'core/providers/respuestas_encuesta_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'screens/onboarding_flow.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MainTabProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => SimulacionesProvider()),
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
