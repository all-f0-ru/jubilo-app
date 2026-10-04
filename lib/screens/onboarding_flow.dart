import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/jubilo_widgets.dart';
import 'home_screen.dart';

/// Splash: logo + tagline, pasa sola a Bienvenida después de un
/// momento breve.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen(pageIndex: 0)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_rounded, size: 72, color: AppColors.coral),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: 'Jubilo', style: AppTextStyles.display(1.2)),
                TextSpan(
                  text: '.',
                  style: AppTextStyles.display(1.2, color: AppColors.coral),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Tu jubilación, explicada con calma',
                style: AppTextStyles.small(1.0)),
          ],
        ),
      ),
    );
  }
}

/// 2️⃣ y 3️⃣ Bienvenida (1 de 2) y (2 de 2). Se maneja con un solo widget
/// parametrizado por [pageIndex] (0 o 1) para no duplicar código.
class WelcomeScreen extends StatelessWidget {
  final int pageIndex; // 0 = pantalla 1, 1 = pantalla 2

  const WelcomeScreen({super.key, required this.pageIndex});

  static const _titles = [
    'Bienvenido a Jubilo',
    '¿Qué puedes hacer aquí?',
  ];

  static const _bodies = [
    'Esta app está hecha especialmente para personas que se están '
        'acercando a la edad de jubilarse en Chile.\n\n'
        'Aquí encontrarás información clara y sencilla, sin palabras '
        'complicadas.',
    'Puedes aprender sobre tu situación previsional paso a paso, o '
        'simular cómo funcionarían las distintas modalidades de pensión '
        'para tu caso.\n\n'
        'Todo pensado para leerse con calma, a tu ritmo.',
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = pageIndex == 1;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.wb_sunny_rounded, size: 56, color: AppColors.coral),
              const SizedBox(height: 24),
              Text(
                _titles[pageIndex],
                textAlign: TextAlign.center,
                style: AppTextStyles.display(1.0),
              ),
              const SizedBox(height: 20),
              Text(
                _bodies[pageIndex],
                textAlign: TextAlign.left,
                style: AppTextStyles.body(1.0),
              ),
              const Spacer(),
              ProgressDots(total: 2, activeIndex: pageIndex),
              const SizedBox(height: 20),
              PrimaryButton(
                label: isLast ? 'Comenzar' : 'Siguiente',
                onPressed: () {
                  if (isLast) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const FontSetupScreen()),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(pageIndex: 1)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4️⃣ Ajuste inicial de tamaño de letra, con vista previa en vivo.
class FontSetupScreen extends StatelessWidget {
  const FontSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scale = settings.fontScale.multiplier;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '¿Quieres que el texto se vea más grande?',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(1.0),
              ),
              const SizedBox(height: 24),

              // Vista previa en vivo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.creamDeep, width: 2),
                ),
                child: Text(
                  'Así se vería un texto de ejemplo en Jubilo.',
                  style: AppTextStyles.body(scale),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: FontScaleLevel.values.map((level) {
                  final selected = settings.fontScale == level;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () =>
                            context.read<SettingsProvider>().setFontScale(level),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              selected ? AppColors.teal : Colors.transparent,
                          foregroundColor:
                              selected ? Colors.white : AppColors.tealDeep,
                          side: BorderSide(
                              color: AppColors.teal, width: selected ? 0 : 2),
                        ),
                        child: Text(level.label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continuar',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
