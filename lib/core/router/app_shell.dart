import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/design_system/design_system.dart';
import 'app_tab.dart';
import 'tab_badges.dart';

/// Scaffold externo das abas: hospeda o `IndexedStack` do go_router e a
/// [AppBottomNav]. Cada aba desenha a própria app bar. A aba Alertas mostra
/// o número de não lidos.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertsCountProvider) ?? 0;
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
              badgeCount: tab == AppTab.notifications ? unread : 0,
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
