import 'package:flutter/material.dart';

/// Um destino da [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
    this.badgeCount = 0,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Contador exibido no badge (ex.: notificações não lidas). 0 = sem badge.
  final int badgeCount;
}

/// Barra de navegação inferior do app (5 abas). Fina camada sobre
/// [NavigationBar] para padronizar badges e ícone selecionado.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final item in items)
          NavigationDestination(
            label: item.label,
            tooltip: item.label,
            icon: _maybeBadge(item.badgeCount, Icon(item.icon)),
            selectedIcon: _maybeBadge(item.badgeCount, Icon(item.selectedIcon)),
          ),
      ],
    );
  }

  Widget _maybeBadge(int count, Widget child) {
    if (count <= 0) return child;
    return Badge(label: Text(count > 99 ? '99+' : '$count'), child: child);
  }
}
