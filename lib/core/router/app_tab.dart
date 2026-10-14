import 'package:flutter/material.dart';

/// As 5 abas da bottom nav, na ordem do handoff. O índice do enum é o índice
/// do branch no `StatefulShellRoute` e o da `AppBottomNav`.
enum AppTab {
  dashboard(
    path: '/dashboard',
    label: 'Início',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  environments(
    path: '/environments',
    label: 'Ambientes',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment,
  ),
  automations(
    path: '/automations',
    label: 'Automações',
    icon: Icons.bolt_outlined,
    selectedIcon: Icons.bolt,
  ),
  notifications(
    path: '/notifications',
    label: 'Alertas',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  settings(
    path: '/settings',
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AppTab({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Caminho raiz da aba; sub-rotas das features ficam abaixo dele.
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
