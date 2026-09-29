import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding_flow.dart';
import 'core/theme/app_text_styles.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
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