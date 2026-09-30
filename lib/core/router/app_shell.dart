import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/design_system/design_system.dart';
import 'app_tab.dart';

/// Scaffold externo das abas: hospeda o `IndexedStack` do go_router e a
/// [AppBottomNav]. Cada aba desenha a própria app bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        items: [
          for (final tab in AppTab.values)
            AppBottomNavItem(
              icon: tab.icon,
              selectedIcon: tab.selectedIcon,
              label: tab.label,
            ),
        ],
      ),
    );
  }

  void _onTabSelected(int index) {
    // Tocar na aba já ativa volta para a raiz dela.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
