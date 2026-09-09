import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

const _items = [
  AppBottomNavItem(icon: Icons.dashboard_outlined, label: 'Início'),
  AppBottomNavItem(icon: Icons.apartment_outlined, label: 'Ambientes'),
  AppBottomNavItem(icon: Icons.bolt_outlined, label: 'Automações'),
  AppBottomNavItem(
    icon: Icons.notifications_outlined,
    label: 'Alertas',
    badgeCount: 3,
  ),
  AppBottomNavItem(icon: Icons.settings_outlined, label: 'Ajustes'),
];

void main() {
  testWidgets('renderiza as 5 abas', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 120),
      AppBottomNav(
        items: _items,
        currentIndex: 0,
        onDestinationSelected: (_) {},
      ),
    );
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('notifica o índice tocado', (tester) async {
    int? selected;
    await pumpComponent(
      tester,
      size: const Size(390, 120),
      AppBottomNav(
        items: _items,
        currentIndex: 0,
        onDestinationSelected: (i) => selected = i,
      ),
    );
    await tester.tap(find.text('Automações'));
    expect(selected, 2);
  });

  testWidgets('mostra o badge de contagem na aba de alertas', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 120),
      AppBottomNav(
        items: _items,
        currentIndex: 0,
        onDestinationSelected: (_) {},
      ),
    );
    expect(find.widgetWithText(Badge, '3'), findsOneWidget);
  });

  testWidgets('golden', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 100),
      padding: EdgeInsets.zero,
      AppBottomNav(
        items: _items,
        currentIndex: 1,
        onDestinationSelected: (_) {},
      ),
    );
    await expectLater(
      find.byType(AppBottomNav),
      matchesGoldenFile('goldens/app_bottom_nav.png'),
    );
  });
}
