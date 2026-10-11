import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/main_tab_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_colors.dart';
import 'home/home_tab_screen.dart';
import 'aprender/tu_situacion_screen.dart';
import 'modalidades/modalidades_list_screen.dart';
import 'simulador/simulador_intro_screen.dart';

/// Shell principal de la app: barra de navegación inferior con 4
/// pestañas (Inicio, Aprender, Modalidades, Simular). Cada pestaña tiene
/// su propio [Navigator] anidado, para poder navegar dentro de ella
/// (ej. tema → contenido) sin perder la barra inferior ni mezclar el
/// historial de "atrás" entre pestañas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _tabs = [
    _TabInfo('Inicio', Icons.home_outlined, Icons.home_rounded),
    _TabInfo('Aprender', Icons.menu_book_outlined, Icons.menu_book_rounded),
    _TabInfo('Modalidades', Icons.layers_outlined, Icons.layers_rounded),
    _TabInfo('Simular', Icons.calculate_outlined, Icons.calculate_rounded),
  ];

  Widget _tabNavigator(int index, Widget root) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => root),
    );
  }

  void _onTap(BuildContext context, int tappedIndex) {
    final tabs = context.read<MainTabProvider>();
    if (tappedIndex == tabs.index) {
      // Si ya estaba en esa pestaña, vuelve a su pantalla raíz.
      _navKeys[tappedIndex].currentState?.popUntil((r) => r.isFirst);
    } else {
      tabs.setTab(tappedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<MainTabProvider>().index;
    final hc = context.watch<SettingsProvider>().highContrast;
    final accent = hc ? Colors.black : AppColors.teal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navKeys[currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (currentIndex != 0) {
          context.read<MainTabProvider>().setTab(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            _tabNavigator(0, const HomeTabScreen()),
            _tabNavigator(1, const TuSituacionScreen()),
            _tabNavigator(2, const ModalidadesListScreen()),
            _tabNavigator(3, const SimuladorIntroScreen()),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: hc ? Colors.white : AppColors.cream,
            indicatorColor: accent.withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : (hc ? Colors.black54 : AppColors.inkSoft),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => _onTap(context, i),
            backgroundColor: hc ? Colors.white : AppColors.cream,
            elevation: 0,
            destinations: _tabs.map((t) {
              return NavigationDestination(
                icon: Icon(t.icon, color: hc ? Colors.black54 : AppColors.inkSoft),
                selectedIcon: Icon(t.selectedIcon, color: accent),
                label: t.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _TabInfo(this.label, this.icon, this.selectedIcon);
}
